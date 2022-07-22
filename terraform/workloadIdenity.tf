# GCP Provider
provider "google" {
  region      = "europe-north1"
  credentials = file("../secret.json")
}

### Variables ###

# normally it goes to 'variables.tf' but this is an example code,
# for better clarity I'll keep it here
variable "project" {
  description = "A GCP project name to operate in"
  type        = "string"
  default     = "my_project"
}

variable "gcp_sa_name" {
  description = "A GCP Service Account name"
  type        = string
  default     = "my-app-gcp-sa"
} 

variable "sa_roles" {
  description = "A list of GCP IAM Roles to assign to GCP SA"
  type        = list
  default     = ["roles/pubsublite.publisher", "roles/pubsublite.subscriber"]
}

### Resources ###

# GCP SA
resource "google_service_account" "sa" {
  project      = var.project
  account_id   = var.gcp_sa_name
}

# To enable k8s SA to work on behalf of GCP SA we need to bind it properly in GCP IAM
# This will enable roles translation to k8s SA by using GKE Workload Identity
# Workload Identity is compiled by next pattern: serviceAccount:PROJECT_ID.svc.id.goog[K8S_NAMESPACE/KSA_NAME]
resource "google_service_account_iam_binding" "k8s-sa-binding-to-gcp-sa" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project}.svc.id.goog[default/my-app-sa]",
  ]
  depends_on = [
    google_service_account.sa
  ]
}

# Assign real roles to GCP SA
# Note! this is a PROJECT level IAM permissions! 
resource "google_project_iam_member" "project_iam_additive" {
  for_each = toset(var.sa_roles)

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
  depends_on = [
    google_service_account.sa
  ]
}
