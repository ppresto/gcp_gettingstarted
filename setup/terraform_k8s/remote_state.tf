/*
terraform {
  backend "gcs" {
    bucket  = "${var.PROJECT}"
    prefix  = "/terraform/cicd"
    credentials = "../secrets/${var.PROJECT}.json"
  }
}*/

terraform {
  backend "gcs" {}
}

data "terraform_remote_state" "state" {
  backend = "gcs"
  config {
    bucket  = "${var.bucket}"
    prefix  = "${var.prefix}"
    credentials = "${var.credentials}"
  }
}
