resource "google_container_cluster" "dev1" {
  name               = "${var.cluster_name}"
  zone               = "${var.cluster_region}-a"
  //remove_default_node_pool = true
  initial_node_count = "${var.gcp_node_count}"

/*  Disabling DR to save $$
  additional_zones = [
    "${var.cluster_region}-b",
    "${var.cluster_region}-c",
  ]
*/
  master_auth {
    username = "${var.linux_admin_username}"
    password = "${var.linux_admin_password}"
  }

  node_config {
    machine_type = "n1-standard-2"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/projecthosting"
    ]

    labels {
      env = "dev"
    }

    tags = ["dev", "training"]
  }
    timeouts {
      create = "10m"
      update = "20m"
    }
}

/*
resource "google_container_node_pool" "pool_1" {
  name       = "ppresto-dev-pool"
  region     = "${var.cluster_region}"
  cluster    = "${google_container_cluster.dev1.name}"
  node_count = 1
  depends_on = ["google_container_cluster.dev1"]

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
*/
