#!/bin/sh
#
# Install package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 5.11.2020
#

dnf -y install git
dnf -y install bash-completion
dnf -y install epel-release
dnf -y install joe

dnf -y update

# EOF
