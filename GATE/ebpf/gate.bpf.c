// GATE — eBPF 기반 런타임 보안 프레임워크
// 1단계 구현: sys_enter_connect 트레이스포인트로 아웃바운드 TCP 연결 감시.
// server.mjs 파드가 화이트리스트에 없는 목적지로 connect()를 시도하면
// 이벤트를 링버퍼에 기록해 유저스페이스 에이전트에 알립니다.

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

#define AF_INET 2

// libc의 <sys/socket.h>와 커널 uapi 헤더를 함께 쓰면 재정의 충돌이 나기 때문에,
// eBPF 프로그램 관례대로 필요한 최소 구조체를 직접 정의합니다.
struct gate_sockaddr {
    unsigned short sa_family;
    unsigned char sa_data[14];
};

struct gate_sockaddr_in {
    unsigned short sin_family;
    unsigned short sin_port;   // 네트워크 바이트오더
    unsigned int sin_addr;     // 네트워크 바이트오더
    unsigned char sin_zero[8];
};

// sys_enter_connect 트레이스포인트가 넘겨주는 필드 레이아웃.
// (실제 커널의 /sys/kernel/tracing/events/syscalls/sys_enter_connect/format 과 일치해야 함)
struct trace_event_raw_sys_enter_connect {
    unsigned long long unused;
    long id;
    long fd;
    struct gate_sockaddr *uservaddr;
    long addrlen;
};

// 허용된 목적지 IPv4 주소 화이트리스트.
// key: 목적지 IP(네트워크 바이트오더), value: 1(허용)
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 256);
    __type(key, __u32);
    __type(value, __u8);
} allowed_ips SEC(".maps");

// 이상 탐지 이벤트를 유저스페이스로 보내는 링버퍼.
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 1 << 16); // 64KB
} events SEC(".maps");

struct gate_event {
    __u32 pid;
    __u32 daddr;   // 목적지 IPv4 (네트워크 바이트오더)
    __u16 dport;   // 목적지 포트 (호스트 바이트오더)
    char comm[16]; // 프로세스명
};

SEC("tracepoint/syscalls/sys_enter_connect")
int trace_connect(struct trace_event_raw_sys_enter_connect *ctx) {
    struct gate_sockaddr sa = {};
    if (bpf_probe_read_user(&sa, sizeof(sa), ctx->uservaddr) != 0) {
        return 0;
    }

    // IPv4만 취급 (1단계 범위 — IPv6은 다음 단계)
    if (sa.sa_family != AF_INET) {
        return 0;
    }

    struct gate_sockaddr_in sin = {};
    if (bpf_probe_read_user(&sin, sizeof(sin), ctx->uservaddr) != 0) {
        return 0;
    }

    __u32 daddr = sin.sin_addr;
    __u8 *allowed = bpf_map_lookup_elem(&allowed_ips, &daddr);
    if (allowed) {
        // 화이트리스트에 있는 정상 목적지 — 조용히 통과
        return 0;
    }

    // 화이트리스트에 없는 목적지 — 이상 이벤트로 기록
    struct gate_event *evt = bpf_ringbuf_reserve(&events, sizeof(*evt), 0);
    if (!evt) {
        return 0;
    }
    evt->pid = bpf_get_current_pid_tgid() >> 32;
    evt->daddr = daddr;
    evt->dport = __builtin_bswap16(sin.sin_port);
    bpf_get_current_comm(&evt->comm, sizeof(evt->comm));
    bpf_ringbuf_submit(evt, 0);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
