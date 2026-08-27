// GATE 유저스페이스 에이전트
//
// 1. gate.bpf.o를 로드하고 tracepoint/syscalls/sys_enter_connect에 attach
// 2. GATE_ALLOWLIST 환경변수(콤마 구분 도메인 목록)를 주기적으로 DNS 조회해서
//    결과 IP를 커널의 allowed_ips 맵에 채워넣음
// 3. 커널이 링버퍼로 보내는 이상 탐지 이벤트를 폴링해서 로그 출력
//
// 실행: ./gate-agent
// 환경변수:
//   GATE_ALLOWLIST   콤마로 구분한 허용 도메인 (기본값: 아래 DEFAULT_ALLOWLIST)
//   GATE_RESOLVE_INTERVAL_SEC   도메인 재조회 주기 (기본 300초)

#include <bpf/libbpf.h>
#include <bpf/bpf.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define DEFAULT_ALLOWLIST \
    "firebaseio.com,googleapis.com,identitytoolkit.googleapis.com," \
    "firestore.googleapis.com,us-south.ml.cloud.ibm.com,serpapi.com"
#define DEFAULT_RESOLVE_INTERVAL 300

struct gate_event {
    unsigned int pid;
    unsigned int daddr;
    unsigned short dport;
    char comm[16];
};

static volatile sig_atomic_t running = 1;

static void handle_sigint(int sig) {
    (void)sig;
    running = 0;
}

// 도메인 목록을 조회해서 allowed_ips 맵(bpf map fd)에 채워넣음.
// 알림 노드 재시작 없이도 도메인의 IP가 바뀌면 자동으로 갱신됩니다.
static void refresh_allowlist(int map_fd, const char *domains) {
    char *copy = strdup(domains);
    char *saveptr = NULL;
    char *domain = strtok_r(copy, ",", &saveptr);
    int resolved = 0;

    while (domain != NULL) {
        struct addrinfo hints = {0};
        struct addrinfo *res = NULL;
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_STREAM;

        if (getaddrinfo(domain, NULL, &hints, &res) == 0) {
            for (struct addrinfo *rp = res; rp != NULL; rp = rp->ai_next) {
                struct sockaddr_in *sin = (struct sockaddr_in *)rp->ai_addr;
                unsigned int ip = sin->sin_addr.s_addr;
                unsigned char allowed = 1;
                bpf_map_update_elem(map_fd, &ip, &allowed, BPF_ANY);
                resolved++;
            }
            freeaddrinfo(res);
        } else {
            fprintf(stderr, "[GATE] 경고: %s 조회 실패\n", domain);
        }
        domain = strtok_r(NULL, ",", &saveptr);
    }
    free(copy);

    time_t now = time(NULL);
    printf("[GATE] %.24s 화이트리스트 갱신 완료 (%d개 IP 등록)\n", ctime(&now), resolved);
}

static int handle_event(void *ctx, void *data, size_t data_sz) {
    (void)ctx;
    if (data_sz < sizeof(struct gate_event)) return 0;
    struct gate_event *e = data;

    struct in_addr addr = { .s_addr = e->daddr };
    time_t now = time(NULL);

    // TODO(2단계): 여기서 execve 이상 탐지도 함께 처리
    // TODO(3단계): Tekton 파이프라인 webhook으로 알림 전송
    fprintf(stderr,
        "[GATE][이상 감지] %.24s pid=%u comm=%s dest=%s:%u — 화이트리스트에 없는 목적지\n",
        ctime(&now), e->pid, e->comm, inet_ntoa(addr), e->dport);
    return 0;
}

int main(void) {
    signal(SIGINT, handle_sigint);
    signal(SIGTERM, handle_sigint);

    const char *allowlist = getenv("GATE_ALLOWLIST");
    if (!allowlist) allowlist = DEFAULT_ALLOWLIST;

    int resolve_interval = DEFAULT_RESOLVE_INTERVAL;
    const char *interval_env = getenv("GATE_RESOLVE_INTERVAL_SEC");
    if (interval_env) resolve_interval = atoi(interval_env);

    struct bpf_object *obj = bpf_object__open_file("gate.bpf.o", NULL);
    if (!obj) {
        fprintf(stderr, "[GATE] eBPF 오브젝트 open 실패\n");
        return 1;
    }
    if (bpf_object__load(obj)) {
        fprintf(stderr, "[GATE] eBPF 프로그램 load 실패 (커널 verifier 거부 또는 권한 부족)\n");
        return 1;
    }

    struct bpf_program *prog = bpf_object__find_program_by_name(obj, "trace_connect");
    struct bpf_link *link = bpf_program__attach(prog);
    if (!link) {
        fprintf(stderr,
            "[GATE] attach 실패 — 이 노드에 tracefs/debugfs가 마운트돼 있는지, "
            "CAP_SYS_ADMIN 권한이 있는지 확인하세요.\n");
        return 1;
    }

    int allowed_ips_fd = bpf_map__fd(bpf_object__find_map_by_name(obj, "allowed_ips"));
    int events_fd = bpf_map__fd(bpf_object__find_map_by_name(obj, "events"));

    printf("[GATE] 실행 시작 — server.mjs의 아웃바운드 연결을 감시합니다.\n");
    refresh_allowlist(allowed_ips_fd, allowlist);

    struct ring_buffer *rb = ring_buffer__new(events_fd, handle_event, NULL, NULL);
    if (!rb) {
        fprintf(stderr, "[GATE] 링버퍼 생성 실패\n");
        return 1;
    }

    time_t last_refresh = time(NULL);
    while (running) {
        ring_buffer__poll(rb, 1000 /* ms */);
        if (time(NULL) - last_refresh >= resolve_interval) {
            refresh_allowlist(allowed_ips_fd, allowlist);
            last_refresh = time(NULL);
        }
    }

    printf("[GATE] 종료 신호 수신, 정리 중...\n");
    ring_buffer__free(rb);
    bpf_link__destroy(link);
    bpf_object__close(obj);
    return 0;
}
