variable "project" {
  type        = "string"
  description = "GCP Project to be used for K8s"
  default     = "enterMyGcpProjectHere"
}

variable "region" {
  type        = "string"
  description = "GCP Project region"
}
variable "bucket" {
  type        = "string"
  description = "GCP Project bucket for state"
}
variable "prefix" {
  type        = "string"
  description = "GCP Project bucket prefix"
}
variable "credentials" {
  type        = "string"
  description = "GCP Project credentials"
}

variable "linux_admin_username" {
  type        = "string"
  description = "User name for authentication to the Kubernetes linux agent virtual machines in the cluster."
}

variable "linux_admin_password" {
  type ="string"
  description = "The password for the Linux admin account."
}

variable "gcp_node_count" {
  type = "string"
  description = "Count of cluster instances to start."
}

variable "cluster_name" {
  type = "string"
  description = "Cluster name for the GCP Cluster."
}

variable "cluster_region" {
  type = "string"
  description = "Cluster region for the GCP Cluster."
}

output "gcp_cluster_name" {
  value = "${google_container_cluster.dev1.name}"
}

output "gcp_cluster_endpoint" {
  value = "${google_container_cluster.dev1.endpoint}"
}

# The following outputs allow authentication and connectivity to the GKE Cluster
# by using certificate-based authentication.
output "client_certificate" {
  value = "${google_container_cluster.dev1.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.dev1.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.dev1.master_auth.0.cluster_ca_certificate}"
}
