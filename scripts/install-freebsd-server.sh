#!/bin/sh
# FreeBSD 15.1 training bootstrap. SSH access is configured before packages.
set -eu
umask 077

: "${EDU_SSH_USER:?SSH user was not passed by create_fbsd_vm_machine.sh}"
: "${EDU_SSH_PUBLIC_KEY:?SSH public key was not passed by create_fbsd_vm_machine.sh}"
case "$EDU_SSH_USER" in
    *[!a-z0-9_-]*|'') echo 'Invalid SSH username' >&2; exit 1 ;;
esac
case "$EDU_SSH_PUBLIC_KEY" in
    'ssh-rsa '*|'ssh-ed25519 '*|'ecdsa-sha2-'*) : ;;
    *) echo 'Invalid SSH public key' >&2; exit 1 ;;
esac

if ! id "$EDU_SSH_USER" >/dev/null 2>&1; then
    pw useradd "$EDU_SSH_USER" -m -G wheel -s /bin/sh
fi
pw groupmod wheel -m "$EDU_SSH_USER" || true
user_home=$(pw usershow "$EDU_SSH_USER" | cut -d: -f9)
[ -d "$user_home" ] || { echo "Missing home directory for $EDU_SSH_USER" >&2; exit 1; }
install -d -o "$EDU_SSH_USER" -m 0700 "$user_home/.ssh"
touch "$user_home/.ssh/authorized_keys"
if ! grep -qxF "$EDU_SSH_PUBLIC_KEY" "$user_home/.ssh/authorized_keys"; then
    printf '%s\n' "$EDU_SSH_PUBLIC_KEY" >> "$user_home/.ssh/authorized_keys"
fi
chown "$EDU_SSH_USER" "$user_home/.ssh/authorized_keys"
chmod 0600 "$user_home/.ssh/authorized_keys"
/usr/sbin/sshd -t
service sshd onestart || service sshd restart
printf 'SSH access prepared for %s\n' "$EDU_SSH_USER"

# Install basic tools from binary packages. Do not build the Ports tree at boot.
pkg update
pkg install -y sudo bash git joe mc screen jq
mkdir -p /usr/local/etc/sudoers.d
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$EDU_SSH_USER" > /usr/local/etc/sudoers.d/zabbix-edu
chmod 0440 /usr/local/etc/sudoers.d/zabbix-edu
if ! grep -q '^#includedir /usr/local/etc/sudoers.d$' /usr/local/etc/sudoers; then
    printf '\n#includedir /usr/local/etc/sudoers.d\n' >> /usr/local/etc/sudoers
fi
/usr/local/sbin/visudo -c

if ! id zbx >/dev/null 2>&1; then
    pw useradd zbx -m -s /bin/sh
fi
if [ ! -s /root/zbx-user.pw ]; then
    openssl rand -base64 32 > /root/zbx-user.pw
fi
pw usermod zbx -h 0 < /root/zbx-user.pw

pkg install -y zabbix7-agent
sysrc zabbix_agentd_enable=YES
agent_conf=/usr/local/etc/zabbix7/zabbix_agentd.conf
if [ -f "$agent_conf" ]; then
    sed -i '' -e 's|^Server=127.0.0.1.*|Server=127.0.0.1,enceladus.pfsense.cz|' "$agent_conf"
fi
service zabbix_agentd restart
printf 'FreeBSD training bootstrap complete.\n'
