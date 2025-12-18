resource "google_storage_bucket" "backup_target" {
  name          = "${var.creator_label}-${terraform.workspace}-k10"
  location      = var.gcp_region
  force_destroy = true
  storage_class = "REGIONAL"
}
