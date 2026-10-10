// SUID helper: creates a real overlay whiteout at the given path.
// Overlayfs blocks direct mknod of char(0,0) on its own filesystems, but
// tmpfs allows it. Mounts a tmpfs over the parent dir, then mknods the
// whiteout. Usage: whiteout-touch <path>  (e.g. whiteout-touch 4/edits.md)
#define _GNU_SOURCE
#include <errno.h>
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <path>\n", argv[0]);
        return 1;
    }

    if (setuid(0) != 0 || setgid(0) != 0) {
        fprintf(stderr, "setuid/setgid: %s (is this binary SUID root?)\n", strerror(errno));
        return 1;
    }

    // dirname() may modify its argument — use a copy
    char parent_buf[PATH_MAX];
    strncpy(parent_buf, argv[1], sizeof(parent_buf) - 1);
    parent_buf[sizeof(parent_buf) - 1] = '\0';
    char *parent = dirname(parent_buf);

    if (mount("tmpfs", parent, "tmpfs", 0, NULL) != 0) {
        fprintf(stderr, "mount tmpfs on %s: %s\n", parent, strerror(errno));
        return 1;
    }

    if (mknod(argv[1], S_IFCHR | 0644, makedev(0, 0)) != 0) {
        fprintf(stderr, "mknod %s: %s\n", argv[1], strerror(errno));
        return 1;
    }

    printf("whiteout created at %s\n", argv[1]);
    return 0;
}
