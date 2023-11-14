#!/bin/sh
#
# Install FreeBSD packages
#
# Lukas Maly <Iam@LukasMaly.NET> 14.12.2023
#

pkg install -y bash joe mc git screen

### zbx user add
openssl rand -base64 32 > /root/zbx-user.pw
ZBX_PASS=`cat /root/zbx-user.pw`

echo "--- ZABBIX ---"
pw useradd zbx -m
pw usermod zbx -g google-sudoers
echo ${ZBX_PASS} | pw usermod zbx -h 0

# reconfigure ssh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config-orig
#echo "AuthenticationMethods publickey,password" >> /etc/ssh/sshd_config
sed -i "" -e 's|#PasswordAuthentication no|PasswordAuthentication yes|g; s|Admin|zbx_probe|g' /etc/ssh/sshd_config
/etc/rc.d/sshd restart

# edit make.conf
echo "BATCH=yes" > /etc/make.conf
echo "ALLOW_UNSUPPORTED_SYSTEM=yes" >> /etc/make.conf

# update ports
pkg install -y portsnap portupgrade
portsnap fetch
portsnap extract

# install ports
cd /usr/ports/devel/p5-JSON-RPC && make install clean
cd /usr/ports/www/p5-LWP-Protocol-https && make install clean

pkg install -y py39-lxml py39-ansible jq
cd /usr/ports/devel/py-pip && make install clean
cd /usr/ports/net-mgmt/py-pyzabbix && make install clean

pip install zabbix-api

# Zabbix agentd
pkg install -y zabbix6-agent
/usr/local/etc/rc.d/zabbix_agentd enable
cp -v /usr/local/etc/zabbix6/zabbix_agentd.conf /usr/local/etc/zabbix6/zabbix_agentd.conf-orig
gsed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /usr/local/etc/zabbix6/zabbix_agentd.conf
gsed -i 's/Server=127.0.0.1/Server=127.0.0.1,enceladus.pfsense.cz/g' /usr/local/etc/zabbix6/zabbix_agentd.conf
gsed -i 's/# LogRemoteCommands=0/LogRemoteCommands=1/g' /usr/local/etc/zabbix6/zabbix_agentd.conf
gsed -i 's/# DenyKey=system.run\[\*\]/AllowKey=system.run\[\*\]/g' /usr/local/etc/zabbix6/zabbix_agentd.conf
diff -u /usr/local/etc/zabbix6/zabbix_agentd.conf-orig /usr/local/etc/zabbix6/zabbix_agentd.conf
/usr/local/etc/rc.d/zabbix_agentd restart

# project zabbix-api
cd /root
git clone https://github.com/smejdil/zabbix-api

# EOF