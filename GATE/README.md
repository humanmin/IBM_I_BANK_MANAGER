# GATE — eBPF 기반 런타임 보안 프레임워크 (1단계)

**상태: 1단계(아웃바운드 연결 감시) 실제 구현 완료.** 코드가 실제로 컴파일되고, 커널
verifier를 통과하며 로드되는 것까지 개발 환경에서 직접 검증했습니다.

## 뭐가 실제로 검증됐고, 뭐가 아직인지 (정직하게)

| 단계 | 검증 여부 | 방법 |
|---|---|---|
| eBPF C 코드 → 바이트코드 컴파일 | ✅ 검증됨 | `clang -target bpf`로 실제 컴파일, `elf64-bpf` 포맷 오브젝트 생성 확인 |
| 커널 verifier 통과 + 실제 로드 | ✅ 검증됨 | `bpf_object__load()` 성공, 맵 2개가 실제 커널 fd로 생성됨을 확인 |
| tracepoint attach (실제 감시 시작) | ⚠️ **미검증** | 개발 샌드박스에 `tracefs`/`debugfs`가 마운트돼 있지 않아 이 환경에서는 attach 자체가 불가능. **실제 OpenShift 노드에서 검증 필요** (표준 노드는 tracefs가 기본 마운트되어 있어 동작할 것으로 예상되나, 확인 전까지는 "예상"으로 남겨둠) |
| 유저스페이스 에이전트(DNS 조회, 링버퍼 폴링) | ✅ 검증됨 | 실제 실행해서 DNS 조회 및 로그 출력 확인, attach 실패 시 명확한 에러 메시지 출력도 확인 |
| DaemonSet으로 OpenShift 배포 | ❌ 미검증 | 실제 클러스터 접근 없이는 검증 불가 |

## 파일 구성

```
GATE/
├── ebpf/
│   └── gate.bpf.c       커널에서 실행되는 eBPF 프로그램
├── agent/
│   └── gate-agent.c     프로그램을 로드·attach하고 이벤트를 처리하는 유저스페이스 에이전트
├── Dockerfile            멀티스테이지 빌드 (clang로 컴파일 → 경량 런타임 이미지)
└── README.md             이 문서

openshift/
└── gate-daemonset.yaml   DaemonSet + ConfigMap(화이트리스트) + ServiceAccount
```

## 동작 원리

1. `gate.bpf.c`가 `sys_enter_connect` 시스템 콜 트레이스포인트에 걸립니다 — 어떤 프로세스든 `connect()`를 호출하는 순간 실행됩니다.
2. 목적지 IPv4 주소가 커널 맵 `allowed_ips`에 있으면 조용히 통과, 없으면 `events` 링버퍼에 이상 이벤트(PID, 프로세스명, 목적지 IP:포트)를 기록합니다.
3. `gate-agent.c`(유저스페이스)가 시작 시 `GATE_ALLOWLIST` 환경변수의 도메인들을 DNS로 조회해 `allowed_ips` 맵을 채우고, 5분(기본값)마다 재조회합니다 — 클라우드 서비스의 IP가 바뀌어도 화이트리스트가 자동으로 갱신됩니다.
4. 링버퍼를 폴링하다가 이상 이벤트가 오면 로그로 출력합니다. (2단계: execve 탐지 추가, 3단계: Tekton 파이프라인 웹훅 연동은 TODO 주석으로 코드에 표시해뒀습니다.)

## 로컬에서 빌드해보기

```bash
docker build -t gate-agent GATE/
```

## 실제 노드에서 테스트하는 방법 (다음 단계)

```bash
# 1. 이미지 빌드 & 클러스터 레지스트리로 push
oc apply -f openshift/gate-daemonset.yaml

# 2. 파드 로그 확인 — "attach 실패" 없이 "실행 시작" 메시지만 나와야 정상
oc logs -l app=gate -f

# 3. 화이트리스트에 없는 목적지로 일부러 연결 시도해서 이상 이벤트가 로그에 찍히는지 확인
oc exec -it <임의의 파드> -- curl http://example.com
```

## 알려진 제약 (1단계 범위 밖)

- IPv6 미지원 (IPv4만)
- DNS 재조회 사이 짧은 시간동안 새로 뜬 IP는 오탐 가능 (5분 주기라 큰 문제는 아님)
- `privileged: true`로 시작 — 검증 후 `capabilities: [SYS_ADMIN, BPF, PERFMON]`로 최소 권한 축소 필요
- 알림이 로그 출력까지만 구현됨 — Slack/Alertmanager 연동은 3단계
