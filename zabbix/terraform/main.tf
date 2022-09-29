provider "vpsadmin" {
  # vpsAdmin API URL (default)
  # Can be also changed using environment variable VPSADMIN_API_URL
  api_url = "https://api.vpsfree.cz"

  # Authentication token
  # Can be also set using environment variable VPSADMIN_API_TOKEN
  auth_token = var.vpsadmin_token
}

# Declare a public key for connection over SSH
resource "vpsadmin_ssh_key" "TR-key" {
  label = "TR"

  # Set your public key here. The file has to contain exactly one public key.
  key = file("~/.ssh/id_ed25519_terraform.pub")
}

# Create a VPS
resource "vpsadmin_vps" "zbx62" {
  # Location label
  # Possible values
  #   - using vpsfree-client: vpsfreectl location list -o label
  #   - using curl: curl https://api.vpsfree.cz/locations
  location = "Staging"

  # OS template name
  # Possible values
  #   - using vpsfree-client: vpsfreectl os_template list -o name
  #   - using curl: curl https://api.vpsfree.cz/os_templates
  #install_os_template = "debian-11-x86_64-vpsadminos-minimal"
  install_os_template = "ubuntu-20.04-x86_64-vpsadminos-minimal"

  # vpsAdmin-managed hostname
  hostname = "zbx62"

  # Number of CPU cores
  cpu = 8

  # Available memory in MB
  memory = 4096

  # Root dataset size in MB
  diskspace = 122880

  # Public keys deployed to /root/.ssh/authorized_keys
  ssh_keys = [
    vpsadmin_ssh_key.TR-key.id,
  ]

  # Execute script on remote vm after this creation
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "apt-get update",
      "apt-get -y install joe mc ansible",
      ]
  
    connection {
     type = "ssh"
     host = vpsadmin_vps.zbx62.public_ipv4_address
  
     # Set your private key here
     private_key = file("~/.ssh/id_ed25519_terraform")
      user        = "root"
      timeout     = "2m"
    }
  }
}
