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

variable "subscr_name" {
  description = "A GCP PubSub Subcription name"
  type        = string
  default     = "my-app-subscription"
}

### Resources ###

resource "google_pubsub_subscription" "subscription" {
  project = var.project
  name    = var.subscr_name
  topic   = "my-app-topic"

  ack_deadline_seconds = 10
  message_retention_duration = "604800s"
  retain_acked_messages = false
  enable_message_ordering = false

  filter = "attributes.x-website = \"filter-Attr\""

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

}

resource "google_pubsub_subscription_iam_member" "iam_role" {
  subscription = var.subscr_name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:my-app-gcp-sa@my-project.iam.gserviceaccount.com"
}
