provider "google" {
  credentials = "${file("../secrets/${var.project}.json")}"
  //project     = "cicd-234921"
  project       = "${var.project}"
  region      = "${var.cluster_region}"
}
