terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.91.0" 
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.178.41:8006/"
  insecure = true # Set to false if you have valid SSL

  ssh {
    agent    = true
    username = "root" 
    # If not using an ssh-agent, uncomment the line below:
    private_key = file("~/.ssh/id_ed25519")
  }
}

locals {
  ssh_public_key = file("~/.ssh/id_ed25519.pub")
}