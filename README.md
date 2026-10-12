# Container Lab

A hands-on lab for learning what a Linux container actually is: a process in running in namespaces, with cgroup limits, running against a mounted rootfs.

Each lab is a shell script "bomb" that checks whether the environment it's running in matches specific isolation criteria. Students have to build that environment by hand using `unshare`, `pivot_root`, `ip netns`, `mount`, and friends. If the environment is wrong, the bomb explodes. If it's right, it defuses.

The whole lab runs inside a privileged container so nothing on your host is at risk.

## Quickstart

Requires Docker or Podman.

```sh
git clone https://github.com/molitorclay/container-lab
cd container-lab
./build.sh
```

You land in a tmux session with one window per lab. `Ctrl+a n` to switch windows, `Ctrl+a arrow` to switch panes, or click the tabs on the bottom of the terminal.

## Labs

| Lab | Topic | Primitives | What you'll learn |
|---|---|---|---|
| **A** | PID namespace | `unshare --pid --fork`, `mount -t proc` | Why PID 1 inside a container isn't PID 1 on the host, and why `/proc` needs remounting after unsharing. |
| **B** | Mount namespace + rootfs isolation | `chroot` or `pivot_root`, bind mounts | The difference between `chroot` and `pivot_root`, and why bind mounts matter for giving a container a filesystem view. |
| **C** | Network namespace | `ip netns`, `veth`, `nftables` NAT | How a container gets a network: veth pairs, routing between namespaces, and NAT masquerade for outbound traffic. |
| **Ch** | Combined challenge | all of the above + user, UTS, timezone | Composing namespaces into something that actually looks like a container, including user ID mapping and hostname isolation. |
| **D** | OverlayFS and whiteouts | `mount -t overlay`, `mknod` char(0,0) | How container images stack as layers, what a whiteout is at the filesystem level, and why `rm` in a Dockerfile doesn't actually delete. |
| **X** | OCI image layers | `podman save`, extract tarballs, mount as overlay | What's inside an OCI image on disk: unpacking layer tarballs and reconstructing the merged rootfs by hand. |

Each lab directory has a `bomb.sh` (the challenge) and a `.solution.sh` (the answer, hidden don't read it unless you get stuck).

## Walkthrough

`walkthrough.md` has the generic commands you'll need, but with no lab-specific context. Use it as a cheat sheet.

## Slides

Talk slides: [docs/slides.pdf](docs/slides.pdf)
([Google Slides version](https://docs.google.com/presentation/d/1ePzOc744MdQjqzpaKLYSO50IIyYJq-bwqD0jWK7x4WU/edit))

## How it's put together

- `Dockerfile` builds a Fedora-based image with jerry (unprivileged user), tmux, and all the networking/overlay tooling.
- `entrypoint.sh` launches tmux with the labs pre-arranged.
- `helper-B.sh` writes fresh SHA256 hashes into `flag_public` / `flag_private` every second, so lab B can verify the student mounted the real file rather than copying stale content.
- `helper-C.sh` listens on port 1234 so lab C's bomb can detect whether the student has actually isolated the network namespace from the host.
- `lab/D/whiteout-touch` is a tiny SUID C binary that creates an overlayfs whiteout, since the kernel blocks direct `mknod c 0 0` from userspace on overlay filesystems.
