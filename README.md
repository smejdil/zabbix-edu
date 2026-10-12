## Deploy zabbix servers on GCP

This small project is used for install EDU servers with Zabbix 7.0 LTS on Ubuntu 26.04 LTS.

## Dependencies

- Package on desktop - google-cloud-sdk - Google Cloud SDK for Google Cloud Platform
- Package on desktop - py37-cloudflare - Wrapper for the Cloudflare v4 API

## How it works

By Google Cloud SDK is intalled servers zbx01-0X. After instalation run scripts for reconfigure OS and install Zabbix for education.

## Features

- Install and configure MySQL
- Install and configure zabbix_server 7.0 LTS
- Install and configure zabbix_agent2 7.0 LTS
- Install and configure Apache 2.4 and PHP-FPM (Ubuntu default version)
- Install unixODBC tools (MySQL ODBC driver requires separate setup on Ubuntu 26.04)
- Install and configure Zabbix API scripts Perl and CPAN modul
- Install and configure with built-in Ansible modules; training setup uses the Zabbix JSON-RPC API
- Install and configure crontab file
- Install and configure Windows server 2019
- Install and configure Tomcat, PostgreSQL, Memcached, Docker ...
- Install and configure FreeBSD server

### Installation

- Configure Google Cloud SDK

```console
gcloud config set compute/zone [ZONE]
gcloud config set compute/region [REGION]
gcloud config set project [PROJECT]
```
## Zabbix servers
- Create VM Zabbix EDU

```console
./zabbix-edu/scripts/create_zabbix_vm_machines.sh 01 02 03
```
### Automated installation (Ubuntu 26.04)

The VM startup script installs MySQL, Zabbix 7.0, Agent 2, Java Gateway,
Apache and PHP-FPM. It writes the frontend configuration, imports the initial
DB schema only into an empty database and configures the training group,
user, timezone and templates through the API. No Galaxy dependencies are used
by this installation path. The older API playbooks remain available separately.

Run the creation script from the parent directory as shown above, or run
`./scripts/create_zabbix_vm_machines.sh 01` from the repository directory.
Defaults: project `datascript-zabbix-edu`, zone `europe-central2-b`, image family
`ubuntu-2604-lts-amd64`, machine `e2-medium`, disk `30GB`. Override using
`PROJECT`, `ZONE`, `IMAGE_FAMILY`, `MACHINE_TYPE`, `BOOT_DISK_SIZE` environment
variables. Existing GCP network/firewall rules associated with the VM tags
are required; the script does not create firewall rules.

**Deploy these repository changes to the GitHub repository before creating a VM.**
The startup script clones `https://github.com/smejdil/zabbix-edu`; local changes
alone do not update the playbook downloaded by a new VM.

On the VM, monitor installation with:

```console
sudo tail -f /var/log/zabbix-edu-install.log
sudo journalctl -u google-startup-scripts.service
sudo cat /root/Done
```

`/root/Done` is written only after installation, API configuration and service
checks succeed. The frontend is available at `http://VM_IP/zabbix/`, login
`Admin` with the generated password in `/root/zabbix-admin.pw` (root-only file).
The initial `Admin` / `zabbix` password is changed automatically through the
Zabbix API before the rest of the training configuration. During initial setup
the frontend accepts only local connections; public access opens after the
password change and final service checks. The `zbx_probe` API user receives a
separate generated password in `/root/zbx-probe.pw`.
System passwords are stored in `/root/root-user.pw` and `/root/zbx-user.pw`.
Passwords are preserved when resuming. Startup skips completed installations.
After all VMs finish, collect their URLs and passwords on your workstation:

```console
./zabbix-edu/scripts/collect_zabbix_credentials.sh 01 02 03
```

With no numbers, the script collects all `zbxNN` VMs in the configured GCP
project and zone. It writes `files/zabbix-training-credentials.txt` in the
repository with mode `0600`; the file is ignored by Git. Use `OUTPUT=/path/to/file`
to choose another destination. Collection requires `/root/Done` on every VM
and replaces the file only after every VM succeeds.
To rotate the GUI Admin password and configure training users on an existing
VM after updating the checkout, run:

```console
sudo python3 /root/zabbix-edu/scripts/configure_zabbix_training.py
```

For Admin only, append `--rotate-admin-only`. If Admin was already changed
manually, supply its current
password as `ZABBIX_PASSWORD` in the root environment for this one run.
To retry an interrupted installation after correcting the files on the VM:

```console
sudo bash /root/zabbix-edu/scripts/install-zabbix-gcp.sh
```

An existing checkout is reused, not automatically updated. Update it explicitly
before retrying if the fix was published to GitHub. A partial DB schema import
requires inspection/recovery; the installer does not drop an existing database.
Imported training templates are available for classroom exercises and are not
automatically linked to hosts. SNMP trap reception and exercise-specific hosts
remain classroom configuration steps. Optional Perl API examples and backup
scheduling are not installed by this path.

- Connect to VM Zabbix EDU for some reconfiguration

```console
gcloud compute ssh zbx01 --zone=europe-central2-b
sudo su -
```
- List Zabbix EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5"/zabbix/"}' | grep zbx0
zbx01 - http://35.246.211.200/zabbix/
zbx02 - http://34.89.152.77/zabbix/
zbx03 - http://34.107.115.225/zabbix/

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz/zabbix/"}' | grep zbx0
34.89.152.77 - http://zbx01.pfsense.cz/zabbix/
35.198.167.115 - http://zbx02.pfsense.cz/zabbix/
34.107.115.225 - http://zbx03.pfsense.cz/zabbix/
```
## Linux server for EDU
- Create VM Linux + Tomcat other

```console
./zabbix-edu/scripts/create_tomcat_vm_machine.sh 01
```
- Connect to VM Linux + Tomcat and run scripts + reboot SELinux disable

```console
gcloud compute ssh linsrv01 --zone=europe-west4-a
sudo su -
./zabbix-edu/scripts/reconfigure_sshd.sh
./zabbix-edu/scripts/install_configure_app.sh

systemctl enable vault.service
systemctl start vault.service

https://linsrv01.pfsense.cz:8200
Manual Inicialization
 1 - 1
 Initial
   hvs.XXX
 Key 1
   XXX
```
- List Linux servers EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep linsrv0
linsrv01 - http://34.107.114.128

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep linsrv0
34.107.114.128 - http://linsrv01.pfsense.cz
```

## FreeBSD server for EDU
- Create VM FreeBSD

```console
./zabbix-edu/scripts/create_fbsd_vm_machine.sh 01
```

The FreeBSD 15.1 creation script puts your local
`~/.ssh/google_compute_engine.pub` key directly into the VM's `ssh-keys`
metadata for the local username and disables OS Login on this VM. Its startup
script also creates the account and key as a fallback before package installation.
Override the username or key pair with `SSH_USER`, `SSH_PUBLIC_KEY_FILE`, and
`SSH_PRIVATE_KEY_FILE` if needed. Use the same private key when connecting, for
example `gcloud compute ssh fbsdsrv01 --zone=europe-west4-a
--ssh-key-file="$HOME/.ssh/google_compute_engine"`. The VM creation script
uses an absolute path to the startup script, so it also works when run from
the repository directory. The FreeBSD bootstrap installs binary packages and
Zabbix agent. The former Ports and Python/Perl API build steps were removed
because they failed on FreeBSD 15.1; add those tools separately after SSH
access is confirmed.

- Connect to VM FreeBSD

```console
gcloud compute ssh fbsdsrv01 --zone=europe-west4-a
```
- List FreeBSD servers EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep fbsdsrv0
fbsdsrv01 - http://34.107.114.182

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep fbsdsrv0
34.107.114.182 - http://fbsdsrv01.pfsense.cz
```

- Post install upgrade

```console
portsnap fetch && portsnap update && pkg version -v | grep upd
portupgrade -a
```

## Windows server for EDU
- Create VM Windows server 2019

```console
./zabbix-edu/scripts/create_windows_vm_machine.sh 01
```
- List Windows servers EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep winsrv0
winsrv01 - http://34.89.189.246

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep winsrv0
34.89.189.246 - http://winsrv01.pfsense.cz
```
Manual configure Win server and install IIS and Zabbix agent 2.

```console
less ./zabbix-edu/docs/Windows-on-GCP.txt
```

## pfSense CE on GCP for EDU
- Create VM firewall pfSense

Manual deploy on GCP web console.

```console
less ./zabbix-edu/docs/pfSense-CE-on-GCP.txt
```

- List pfSense firewall EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep pfsense
pfsense-edu - http://34.90.171.187

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep pfsense
34.90.171.187 - http://pfsense-edu.pfsense.cz
```

## DNS A records for EDU
- Create DNS records via cloudflare API

```console
./zabbix-edu/scripts/create_dns_records.sh

cli4 --post name='zbx01' type=A content="35.246.211.200" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx02' type=A content="34.89.152.77" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx03' type=A content="34.107.115.225" /zones/:pfsense.cz/dns_records
cli4 --post name='winsrv01' type=A content="34.107.108.40" /zones/:pfsense.cz/dns_records
cli4 --post name='linsrv01' type=A content="34.107.28.86" /zones/:pfsense.cz/dns_records
cli4 --post name='pfsense01' type=A content="34.90.171.187" /zones/:pfsense.cz/dns_records
```

List of Zabbix server domain and IPv4

```console
for i in {01..12}; do host zbx$i.pfsense.cz; done
zbx01.pfsense.cz has address 35.246.211.200
zbx02.pfsense.cz has address 34.89.152.77
zbx03.pfsense.cz has address 34.107.115.225
```

## HTML list of VM
- Create HTML list of running EDU VM

```console
./zabbix-edu/scripts/create_html_list.sh
```
## Other training projects

- [Zabbix API](https://github.com/smejdil/zabbix-api)
- [Zabbix auto-registration](https://github.com/smejdil/zbx-auto-reg-demo-gcp)
- [Zabbix Docker TimescaleDB](https://github.com/smejdil/zabbix-docker-timescaledb)

## To do

- Import media Email by Zabbix API - Anslible
- Download and Install Zabbix Agent 2 on winsrv01 by PowerShell
- Install - Web Server and IIS Management Scripts and Tools on winsrv01 by PowerShell
- Other ...
