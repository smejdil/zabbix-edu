#!/bin/sh
#
# Install package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 6.11.2020
#

INSTALL_DIR='/usr/share/zabbix';

install -g apache -o apache -m 700 auth.pl $INSTALL_DIR/
install -g apache -o apache -m 700 hosts.pl $INSTALL_DIR/
install -g apache -o apache -m 644 perl_auth.php $INSTALL_DIR/
install -g apache -o apache -m 644 perl_hosts.php $INSTALL_DIR/

# EOF
