# GATE — 빌드 스테이지
FROM ubuntu:24.04 AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    clang llvm libbpf-dev gcc make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY ebpf/gate.bpf.c ebpf/
COPY agent/gate-agent.c agent/

# eBPF 바이트코드 컴파일
RUN clang -O2 -g -target bpf -D__TARGET_ARCH_x86 \
    -I/usr/include/x86_64-linux-gnu \
    -c ebpf/gate.bpf.c -o gate.bpf.o

# 유저스페이스 에이전트 컴파일
RUN gcc -O2 -o gate-agent agent/gate-agent.c -lbpf

# ── 런타임 스테이지 ──────────────────────────────────────────
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    libbpf1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /gate
COPY --from=build /build/gate.bpf.o .
COPY --from=build /build/gate-agent .

# eBPF 로드/attach는 CAP_BPF, CAP_SYS_ADMIN(또는 CAP_PERFMON) 권한과
# /sys/kernel/debug, /sys/fs/bpf 마운트가 필요합니다 — DaemonSet 매니페스트에서 부여.
ENTRYPOINT ["/gate/gate-agent"]
