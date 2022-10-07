output "PublicIPv4" {
  value = vpsadmin_vps.zbx64.public_ipv4_address
}

output "PrivateIPv4" {
  value = vpsadmin_vps.zbx64.private_ipv4_address
}

output "PublicIPv6" {
  value = vpsadmin_vps.zbx64.public_ipv6_address
}

#output "NasMountCommand" {
#    value = "mount -t nfs ${vpsadmin_dataset.nas-backups.export_ip_address}:${vpsadmin_dataset.nas-backups.export_path} /mnt/backups"
#}
