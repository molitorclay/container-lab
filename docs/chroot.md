# chroot

`chroot(2)` changes the apparent root directory for the calling process. All path lookups starting from `/` resolve within the new root. It is the ancestor of modern container filesystem isolation.

## Kernel permission check

`chroot` requires `CAP_SYS_CHROOT` in the calling process's user namespace. From `fs/open.c`:

```c
error = -EPERM;
if (!ns_capable(current_user_ns(), CAP_SYS_CHROOT))
    goto dput_and_out;
error = security_path_chroot(&path);
if (!error)
    set_fs_root(current->fs, &path);
```

`ns_capable` checks the capability within the current user namespace — so a user namespace mapped to uid 0 (via `--user --map-root-user`) satisfies the check without real root on the host. `security_path_chroot` is the LSM hook (SELinux/AppArmor); an `EACCES` instead of `EPERM` means it was blocked there.

## coreutils wrapper

The `chroot(1)` command is a thin wrapper in `src/chroot.c`:

```c
if (chroot (newroot) != 0)
  error (EXIT_CANCELED, errno, _("cannot change root directory to %s"),
         quoteaf (newroot));
```

The error message and exit code come from coreutils; the `errno` value (`EPERM`, `EACCES`, etc.) comes from the kernel.

## Usage

```sh
# requires CAP_SYS_CHROOT — use sudo or a user namespace
sudo chroot /path/to/rootfs /bin/sh

# unprivileged via user namespace
unshare --user --map-root-user chroot /path/to/rootfs /bin/sh
```

---

## Escape techniques

`chroot` is not a security boundary. A process with `CAP_SYS_CHROOT` inside a chroot can escape it entirely.

### 1. Double-chroot (classic)

A privileged process can chroot again to walk back out:

```c
mkdir("escape");
chroot("escape");       // chroot into a subdir
chdir("../../../..");   // walk up past the original root
chroot(".");            // re-root at the real filesystem root
```

The kernel tracks the root and cwd separately. After the first chroot, `cwd` still points outside if you didn't `chdir` into the new root — so `..` traversal escapes.

### 2. Open fd before chroot

A file descriptor opened before `chroot` retains access to the real filesystem:

```c
int fd = open("/", O_RDONLY);   // open real root
chroot("/tmp/jail");
fchdir(fd);                      // jump back out via the fd
chdir("../../../..");
chroot(".");                     // re-root at real /
```

This is why `chroot` without a mount namespace is insufficient — open fds are inherited across `chroot`.

### 3. Mount namespace bypass

Without `--mount`, the chroot shares the host's mount namespace. Any process inside can see `/proc/*/root` symlinks pointing to the real roots of other processes, and follow them out.

---

## Why pivot_root is better

`pivot_root(2)` moves the entire root mount, then allows the old root to be unmounted. Combined with a new mount namespace (`--mount`), the old filesystem tree is completely unreachable — there are no fds, no `..` paths, and no `/proc` leaks that can escape.

```sh
unshare --mount bash
mount --bind $TARGET $TARGET
pivot_root $TARGET $TARGET/.old_root
umount -l /.old_root
rmdir /.old_root
```

The kernel enforces this at the VFS level — once unmounted, the old root is gone from the namespace entirely.
