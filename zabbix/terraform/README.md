# Zabbix server on vpsAdmin VPS configuration
Terraform example configuration creates one VPS with `remote-exec` provisioner
and deploys a public key.

Inspired by [blog.vpsfree.cz][https://blog.vpsfree.cz/terraform-provider-pro-vpsadmin-spravujte-infrastrukturu-automatizovane/].

## Obtaining API authentication token
The provider needs an authentication token to the vpsAdmin API. The token can
be obtained using any of [HaveAPI clients](https://github.com/vpsfreecz/haveapi),
but the provider also comes with a simple CLI utility [get-token](../get-token).

For this example, the token should be put in an arbitrary tfvars file, e.g.
`token.auto.tfvars`:

```
ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519_terraform
get-token -user VPSFREEUSER https://api.vpsfree.cz
get-token -tfvars token.auto.tfvars
Username: VPSFREEUSER
Password: ***********

vpsadmin_token = "your token"
```

## Setup
Edit `main.tf` and set up your public key for deployment and private key
for provisioner.

## Run it
```sh
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding vpsfreecz/vpsadmin versions matching ">= 1.0.0"...
- Installing vpsfreecz/vpsadmin v1.0.0...
- Installed vpsfreecz/vpsadmin v1.0.0 (self-signed, key ID 1C85E54DB0A12B16)

...

Terraform has been successfully initialized!

$ terraform validate
Success! The configuration is valid.

$ terraform plan
$ terraform apply
...
  Enter a value: yes

vpsadmin_ssh_key.DS-key: Creating...
vpsadmin_ssh_key.DS-key: Creation complete after 0s [id=2575]
vpsadmin_vps.zbx62: Creating...
vpsadmin_vps.zbx62: Still creating... [10s elapsed]
vpsadmin_vps.zbx62: Still creating... [20s elapsed]
```
