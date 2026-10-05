# Linux Containerization — Reference

## 1. Kernel Primitives

### Namespaces

| Namespace | `clone()` flag | Isolates |
|---|---|---|
| mount | `CLONE_NEWNS` | Mount points / filesystem view |
| UTS | `CLONE_NEWUTS` | Hostname, domainname |
| IPC | `CLONE_NEWIPC` | SysV IPC, POSIX message queues |
| PID | `CLONE_NEWPID` | Process IDs (container sees PID 1) |
| network | `CLONE_NEWNET` | Interfaces, routing, iptables, sockets |
| user | `CLONE_NEWUSER` | UID/GID mappings, capabilities |
| cgroup | `CLONE_NEWCGROUP` | cgroup root view |
| time | `CLONE_NEWTIME` (5.6) | `CLOCK_MONOTONIC`, `CLOCK_BOOTTIME` offsets |

### Cgroups

- **v1**: per-controller hierarchies (`/sys/fs/cgroup/{memory,cpu,...}`). Being deprecated.
- **v2 ("unified")**: single hierarchy at `/sys/fs/cgroup`. Required for rootless resource management via systemd delegation. Default on Fedora, Debian 11+, Ubuntu 21.10+, RHEL 9+.

### chroot vs pivot_root

- **chroot(2)**: changes the apparent root for the calling process. Escapable by a privileged process via open file descriptors. Not sufficient for container isolation.
- **pivot_root(2)**: swaps the root mount with a new one, allowing the old root to be fully unmounted. Standard secure approach used by all OCI runtimes.
- **MS_MOVE + chroot**: fallback when `pivot_root` is unavailable (e.g. rootfs on `ramfs`).

### Minimal container — bare syscalls

```c
int flags = CLONE_NEWNS | CLONE_NEWUTS | CLONE_NEWIPC
          | CLONE_NEWPID | CLONE_NEWNET | CLONE_NEWUSER | CLONE_NEWCGROUP;
pid_t pid = clone(child_fn, stack+SZ, flags | SIGCHLD, arg);

// in child:
mount("overlay", "/newroot", "overlay", 0, "lowerdir=...,upperdir=...,workdir=...");
mount("proc",   "/newroot/proc", "proc",  0, NULL);
mount("tmpfs",  "/newroot/dev",  "tmpfs", 0, NULL);
mount("sysfs",  "/newroot/sys",  "sysfs", MS_RDONLY, NULL);

chdir("/newroot");
syscall(SYS_pivot_root, ".", ".");
umount2(".", MNT_DETACH);
chdir("/");

prctl(PR_SET_NO_NEW_PRIVS);
seccomp(SECCOMP_SET_MODE_FILTER, …);
execve("/bin/sh", argv, envp);
```

Every tool below is a variation on this skeleton.

---

## 2. Tools Overview

### Full container runtimes / engines
- **Docker** — most popular; daemon-based, OCI images, huge ecosystem.
- **Podman** — daemonless, rootless-first, Docker-CLI compatible (Red Hat).
- **containerd** — lower-level runtime used by Docker/Kubernetes.
- **CRI-O** — Kubernetes-focused OCI runtime.
- **LXC / LXD (Incus)** — "system containers" (full OS, more VM-like than app containers).

### Low-level OCI runtimes
- **runc** — reference OCI runtime.
- **crun** — C implementation, faster, better cgroups v2.
- **youki** — Rust implementation.
- **gVisor (runsc)** — userspace kernel sandbox.
- **Kata Containers** — containers inside lightweight VMs.
- **Firecracker** — microVMs (AWS Lambda/Fargate).

### Sandboxing / lightweight isolation
- **Bubblewrap (bwrap)** — unprivileged namespace sandbox; used by Flatpak.
- **systemd-nspawn** — chroot-on-steroids using namespaces; part of systemd.
- **Firejail** — SUID sandbox for desktop apps.
- **chroot** — the ancestor; filesystem isolation only.

**Main axis:** *application containers* (Docker/Podman — one process, OCI images) vs *system containers* (LXC/nspawn — whole OS) vs *sandboxes* (bwrap/firejail — isolate a single app on the host).

### Master table

| Tool | Namespaces | cgroups | Filesystem isolation | Notes |
|---|---|---|---|---|
| **runc** | all 7 classical | v1 + v2 | `pivot_root` (MS_MOVE+chroot fallback) | OCI reference implementation |
| **crun** | same as runc | v1 + v2 | `pivot_root` | C; ~50% faster than runc |
| **youki** | mnt, uts, ipc, user, pid, net, cgroup | v1 + v2 | `pivot_root` | Rust; drop-in runc replacement |
| **Docker** | delegates to containerd → runc/crun | v1 + v2 via runtime | overlay2; `pivot_root` via runc | Daemon-based |
| **Podman** | delegates to crun (default) | v1 + v2 | overlay/fuse-overlayfs; `pivot_root` | Daemonless; rootless uses user namespace |
| **containerd** | via runc/crun shims | v1 + v2 | overlayfs snapshotters | Core runtime under Docker/Kubernetes |
| **CRI-O** | via runc/crun | v1 + v2 | overlay | Kubernetes-only |
| **LXC / Incus** | ipc, uts, mount, pid, net, user | v1 + v2 | `pivot_root` + chroot | System containers; also AppArmor/seccomp |
| **systemd-nspawn** | mount, pid, ipc, uts, user/net optional | v2 via systemd | `pivot_root` + optional overlay | Supports full OS boot |
| **Bubblewrap** | mount, user, pid, ipc, net, uts | none | tmpfs root + bind mounts; no pivot_root | Unprivileged; backend for Flatpak |
| **Firejail** | mount, pid, ipc, uts, user, net | optional | Optional chroot or tmpfs overlay | SUID binary; seccomp-bpf |
| **gVisor** | host namespaces isolate the Sentry process | host cgroups | Empty mount namespace; Gofer serves files over 9P | Userspace kernel in Go; guest syscalls never reach host |
| **Kata Containers** | N/A at container level — real VM | host cgroups on VMM | VM's own kernel; rootfs via virtio-fs/9p | OCI shim plugs into containerd/CRI-O |
| **Firecracker** | none — microVM | host cgroups on VMM | separate guest kernel | AWS Lambda/Fargate; backing engine for some Kata configs |
| **chroot(1)** | none | none | `chroot(2)` only | Escapable by root; filesystem jail only |

---

## 3. OCI Image Layers & Storage

### How layers become a filesystem

```
registry (index.json → manifest → layer blobs)
   │
   ▼
local store (layers unpacked as directories or snapshots)
   │
   ▼
overlayfs mount (lowerdir per layer, upperdir for writes)
   │
   ▼
runtime pivot_root into merged rootfs → exec entrypoint
```

### OverlayFS

- **lowerdir**: read-only layers, listed bottom-up. Each OCI layer is one entry.
- **upperdir**: writable layer. All container writes land here (copy-on-write).
- **workdir**: kernel scratch space for atomic operations.

Whiteouts (`char 0:0` device nodes) in upperdir mark deleted files. Opaque xattrs (`trusted.overlay.opaque="y"`) hide lower directories entirely.

### Storage drivers

| Driver | Mechanism |
|---|---|
| **overlay2** (default) | Kernel overlayfs |
| **fuse-overlayfs** | Userspace FUSE overlayfs — rootless fallback pre-kernel 5.11 |
| **btrfs** | Each layer is a subvolume; next layer is a CoW snapshot |
| **zfs** | ZFS datasets with clones |
| **devicemapper** | Thin-provisioned block devices. Deprecated. |
| **vfs** | Full recursive copy per layer. No CoW. Correct everywhere, very slow. |

---

## 4. Image Build Tools

| Tool | Notes |
|---|---|
| **Buildah** | Daemonless, rootless. Builds from Dockerfile or shell scripts. OCI or Docker format. |
| **Kaniko** | Builds inside a container/k8s pod — no daemon, no root. Designed for CI. |
| **BuildKit** | Engine behind `docker buildx`. Concurrent stages, secrets, SSH forwarding. |
| **nerdctl** | Docker-compatible CLI for containerd. `nerdctl build` uses BuildKit. |
| **img** | Daemonless, unprivileged. Largely superseded by BuildKit. |
| **skopeo** | Moves/inspects images between registries. Not a builder. |
| **ko** | Builds Go apps into images without a Dockerfile. |
| **Jib** | Same for Java/Maven/Gradle. |
| **apko** | Builds images from apk packages declaratively. Reproducible. |
| **Nix dockerTools** | Reproducible OCI images from Nix expressions. |
| **Bazel rules_oci** | Hermetic, reproducible image builds in Bazel monorepos. |

**Selection guide:**
- CI/k8s without daemon → Kaniko or BuildKit rootless
- Local dev replacing Docker → Podman + Buildah, or nerdctl + BuildKit
- Reproducibility → Nix dockerTools, apko, ko, or Jib
- Moving images between registries → skopeo

### FROM scratch

`scratch` is a reserved magic name — not a real image. When the builder sees `FROM scratch`:
- No parent layer, no inherited files
- Binary must be fully static (no libc, no shell)
- `RUN` is useless; only `COPY`, `ENTRYPOINT`, `CMD`, etc.
- No `/etc/passwd` → use numeric UIDs
- No CA certs → TLS fails unless you COPY in `ca-certificates.crt`

| Tool | Scratch equivalent |
|---|---|
| Buildah | `buildah from scratch` |
| Kaniko / BuildKit / nerdctl | `FROM scratch` in Dockerfile |
| ko | `KO_DEFAULTBASEIMAGE=scratch` |
| apko | Default — empty package list |
| Nix dockerTools | Omit `fromImage` |
| Bazel rules_oci | `base = None` |

---

## Sources

- [OCI Runtime Spec — config-linux.md](https://github.com/opencontainers/runtime-spec/blob/main/config-linux.md)
- [runc libcontainer SPEC.md](https://github.com/opencontainers/runc/blob/main/libcontainer/SPEC.md)
- [runc cgroup-v2 docs](https://github.com/opencontainers/runc/blob/main/docs/cgroup-v2.md)
- [Kernel OverlayFS documentation](https://docs.kernel.org/filesystems/overlayfs.html)
- [Docker storage drivers](https://docs.docker.com/engine/storage/drivers/)
- [containerd snapshotters](https://github.com/containerd/containerd/blob/main/docs/snapshotters/README.md)
- [gVisor security architecture](https://gvisor.dev/docs/architecture_guide/security/)
- [Kata Containers overview](https://katacontainers.io/learn/)
- [LXC introduction](https://linuxcontainers.org/lxc/introduction/)
- [Kernel time namespaces](https://man7.org/linux/man-pages/man7/time_namespaces.7.html)
