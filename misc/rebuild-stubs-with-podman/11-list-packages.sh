#! /usr/bin/env bash
## vim:set ts=4 sw=4 et:
set -e; set -o pipefail
argv0=$0; argv0abs="$(readlink -fn "$argv0")"; argv0dir="$(dirname "$argv0abs")"

# list all system packages that are installed in the image
# using a rootless Podman container

image=upx-stubtools-20221212-v5

podman image list "$image"
echo
podman image tree "$image"

echo 'Packages:'
flags=( --read-only --rm --pull=never )
flags+=( --cap-drop=all )               # drop all capabilities
flags+=( --network=none )               # no network needed
podman run "${flags[@]}" "$image" bash -c $'dpkg -l | sed \'s/ *$//\' | LC_ALL=C sort'

echo
echo 'Packages sorted by Installed-Size:'
podman run "${flags[@]}" "$image" bash -c $'awk \'
{
    if ($1 == "Architecture:") arch = $2;
    if ($1 == "Installed-Size:") size = $2;
    if ($1 == "Package:") p = $2;
    if ($1 == "") {
        printf("%9d %-40s %s\\n", size, p, arch);
        count += 1; total += size;
        arch = ""; size = 0; p = "";
    }
}
END {
    printf("%9d ===== TOTAL (%d packages)\\n", total, count);
}
\' /var/lib/dpkg/status | LC_ALL=C sort -rn'
