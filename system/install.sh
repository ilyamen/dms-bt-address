#!/bin/sh
# Install or remove the system side of the plugin: the address service, its
# polkit action and the helper the settings page runs through pkexec.
#   install.sh [install|uninstall]    as root; PREFIX defaults to /usr/local
set -eu

PREFIX=${PREFIX:-/usr/local}
LIBEXECDIR=$PREFIX/libexec
UNIT=/etc/systemd/system/dms-bt-addr.service
POLICY=/usr/share/polkit-1/actions/io.github.ilyamen.dms-bt-addr.policy
here=$(dirname "$(readlink -f "$0")")

case ${1:-install} in
install)
    install -Dm755 "$here/dms-bt-addr" "$LIBEXECDIR/dms-bt-addr"
    sed "s|@LIBEXECDIR@|$LIBEXECDIR|g" "$here/dms-bt-addr.service.in" | install -Dm644 /dev/stdin "$UNIT"
    sed "s|@LIBEXECDIR@|$LIBEXECDIR|g" "$here/dms-bt-addr.policy.in" | install -Dm644 /dev/stdin "$POLICY"
    systemctl daemon-reload
    systemctl enable dms-bt-addr.service
    systemctl restart dms-bt-addr.service
    ;;
uninstall)
    # Controllers that reload their firmware get the factory address back on
    # the next power-on; the others on reboot.
    systemctl disable --now dms-bt-addr.service 2>/dev/null || true
    rm -f "$UNIT" "$POLICY" "$LIBEXECDIR/dms-bt-addr" /etc/dms-bt-addr.conf
    rm -rf /var/lib/dms-bt-addr
    systemctl daemon-reload
    ;;
*)
    echo "usage: $0 [install|uninstall]" >&2
    exit 2
    ;;
esac
