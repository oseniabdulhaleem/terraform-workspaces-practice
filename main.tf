terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network - Different per workspace
resource "google_compute_network" "vpc" {
  name                    = "vpc-${terraform.workspace}"
  auto_create_subnetworks = false
}

# Subnet with workspace-specific CIDR
resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-${terraform.workspace}"
  ip_cidr_range = local.config.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-${terraform.workspace}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-${terraform.workspace}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Compute Instances - Count varies by workspace
resource "google_compute_instance" "app_server" {
  count        = local.config.instance_count
  name         = "app-${terraform.workspace}-${count.index + 1}"
  machine_type = local.config.machine_type
  zone         = var.zone

  tags = [
    "environment-${terraform.workspace}",
    "ssh-enabled",
    "http-server",
    terraform.workspace
  ]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = local.config.disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata = {
    environment  = terraform.workspace
    managed_by   = "terraform"
    workspace    = terraform.workspace
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>${terraform.workspace} Environment</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: ${local.config.bg_color};
            }
            h1 { color: #333; }
            .info { background: #f4f4f4; padding: 15px; border-radius: 5px; }
            .label { font-weight: bold; }
        </style>
    </head>
    <body>
        <h1>🚀 Welcome to ${upper(terraform.workspace)} Environment</h1>
        <div class="info">
            <p><span class="label">Environment:</span> ${terraform.workspace}</p>
            <p><span class="label">Hostname:</span> $(hostname)</p>
            <p><span class="label">Machine Type:</span> ${local.config.machine_type}</p>
            <p><span class="label">Instance:</span> ${count.index + 1} of ${local.config.instance_count}</p>
            <p><span class="label">Managed by:</span> Terraform Workspaces</p>
        </div>
    </body>
    </html>
HTML
    
    systemctl restart nginx
  EOF

  labels = {
    environment = terraform.workspace
    managed_by  = "terraform"
  }
}

# Storage Bucket - Workspace specific
resource "google_storage_bucket" "app_bucket" {
  name          = "${var.project_id}-${terraform.workspace}-bucket"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    environment = terraform.workspace
    managed_by  = "terraform"
  }
}

# Environment-specific configuration
locals {
  environment_config = {
    dev = {
      instance_count = 1
      machine_type   = "e2-micro"
      disk_size      = 10
      subnet_cidr    = "10.0.1.0/24"
      bg_color       = "#e3f2fd"  # Light blue
    }
    staging = {
      instance_count = 2
      machine_type   = "e2-small"
      disk_size      = 20
      subnet_cidr    = "10.0.2.0/24"
      bg_color       = "#fff3e0"  # Light orange
    }
    prod = {
      instance_count = 3
      machine_type   = "e2-medium"
      disk_size      = 50
      subnet_cidr    = "10.0.3.0/24"
      bg_color       = "#f1f8e9"  # Light green
    }
  }

  # Select config based on current workspace
  config = lookup(local.environment_config, terraform.workspace, local.environment_config.dev)
}