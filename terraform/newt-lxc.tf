resource "proxmox_virtual_environment_container" "newt_lxc" {
  node_name = "pve"
  vm_id     = 501
  unprivileged = false

  initialization {
    hostname = "newt"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  features {
    nesting = true # Required for many tunnel/proxy tools
    
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  cpu { cores = 1 }
  memory { dedicated = 128 }

  disk {
    datastore_id = "local-lvm"
    size         = 2
  }

  network_interface { name = "eth0" }
  
  hook_script_file_id = proxmox_virtual_environment_file.newt_init_script.id
}

resource "proxmox_virtual_environment_file" "newt_init_script" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"
  file_mode    = "0700"

  source_raw {
    data      = templatefile("${path.module}/init-scripts/newt-init.sh", {
      pangolin_endpoint = var.pangolin_endpoint
      newt_id     = var.newt_id
      newt_secret = var.newt_secret
    })
    file_name = "newt-init.sh"
  }
}