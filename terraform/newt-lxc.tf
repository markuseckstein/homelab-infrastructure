resource "proxmox_virtual_environment_container" "newt_lxc" {
  node_name = "pve"
  vm_id     = 501
  unprivileged = true

  initialization {
    hostname = "newt"
    ip_config {
      ipv4 {
        address = "192.168.178.11/24"
        gateway = "192.168.178.1"
      }
    }
    user_account {
      keys = [
        trimspace(local.ssh_public_key)
      ]
    }
  }

  features {
    nesting = true # Required for many tunnel/proxy tools
    keyctl  = true
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.ubuntu_lxc_template.id
    type             = "ubuntu"
  }

  cpu { cores = 1 }
  memory { 
    dedicated = 128
    swap      = 512
   }

  disk {
    datastore_id = "local-lvm"
    size         = 2
  }

  network_interface { name = "eth0" }
  
}

