output "workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_cidr" {
  description = "Subnet CIDR range"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "instance_names" {
  description = "Names of all compute instances"
  value       = google_compute_instance.app_server[*].name
}

output "instance_ips" {
  description = "External IPs of all instances"
  value       = google_compute_instance.app_server[*].network_interface[0].access_config[0].nat_ip
}

output "instance_count" {
  description = "Number of instances in this environment"
  value       = length(google_compute_instance.app_server)
}

output "machine_type" {
  description = "Machine type used for instances"
  value       = local.config.machine_type
}

output "bucket_name" {
  description = "Storage bucket name"
  value       = google_storage_bucket.app_bucket.name
}

output "environment_summary" {
  description = "Summary of current environment configuration"
  value = {
    workspace      = terraform.workspace
    instances      = length(google_compute_instance.app_server)
    machine_type   = local.config.machine_type
    disk_size      = local.config.disk_size
    subnet_cidr    = local.config.subnet_cidr
  }
}

output "web_urls" {
  description = "URLs to access the web servers"
  value = [
    for instance in google_compute_instance.app_server :
    "http://${instance.network_interface[0].access_config[0].nat_ip}"
  ]
}