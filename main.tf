
provider "google" {
  project = var.project_id
  region  = var.default_region
}

provider "google-beta" {
  project = var.project_id
  region  = var.default_region
}

// gke cluster
resource "google_container_cluster" "cluster" {
  name               = var.cluster_name
  location           = var.default_zone
  initial_node_count = 1
  min_master_version = var.cluster_master_version

  network    = "projects/${var.project_id}/global/networks/default"
  subnetwork = "projects/${var.project_id}/global/subnetworks/default"

  remove_default_node_pool = true
}

resource "google_container_node_pool" "pool" {
  provider = google-beta

  name       = var.pool_name
  location   = var.default_zone
  cluster    = google_container_cluster.cluster.name

  initial_node_count = 1

  management {
    auto_repair = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = true
    machine_type = "g1-small"
    disk_size_gb = 10
    disk_type    = "pd-standard" 
    image_type   = "COS_CONTAINERD"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_pubsub_topic" "gke-upgrade-notification" {
  name         = "gke-upgrade-notification"

  message_storage_policy {
    allowed_persistence_regions = [
      var.default_region,
    ]
  }
}


// service account
resource "google_service_account" "output-gke-upgrade-log" {
  account_id  = "output-gke-upgrade-log"
  display_name = "output-gke-upgrade-log"
  description = "GKEのアップグレード通知のログ出力用のサービスアカウント"
}

resource "google_project_iam_member" "output-gke-upgrade-log" {
  count  = length(var.output-gke-upgrade-log-roles)
  role   = element(var.output-gke-upgrade-log-roles, count.index)
  member = "serviceAccount:${google_service_account.output-gke-upgrade-log.email}"
}

variable "output-gke-upgrade-log-roles" {
  default = [
    "roles/logging.logWriter",
  ]
}


// cloud functions
data "archive_file" "function_archive" {
  type        = "zip"
  source_dir  = "src"
  output_path = "src/functions.zip"
}

resource "google_storage_bucket" "source_bucket" {
  name          = var.source_bucket
  location      = var.default_region
  storage_class = "STANDARD"
}

resource "google_storage_bucket_object" "packages" {
  name   = "packages/functions.${data.archive_file.function_archive.output_md5}.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.function_archive.output_path
}

resource "google_cloudfunctions_function" "output-gke-upgrade-log" {
  name                  = var.function_name
  description           = "GKEアップグレード通知をログ出力する"
  runtime               = "go113"
  source_archive_bucket = google_storage_bucket.source_bucket.name
  source_archive_object = google_storage_bucket_object.packages.name
  available_memory_mb   = 128
  timeout               = 60
  entry_point           = "OutputLog"
  service_account_email = google_service_account.output-gke-upgrade-log.email
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource      = google_pubsub_topic.gke-upgrade-notification.id
    failure_policy {
      retry = true
    }
  }
}


// stackdriver logging & monitoring alert
resource "google_logging_metric" "info-gke-upgrade" {
    name = "info_gke_upgrade"
    filter = "resource.type=\"cloud_function\" AND resource.labels.function_name:\"${var.function_name}\" AND textPayload:\"GKE Upgrade start.\""
    description = "GKEアップグレード通知のログベース指標"
    metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "info-gke-upgrade" {
  display_name = "Info - GKE Upgrade"
  combiner     = "OR"
  conditions {
    display_name = "info_gke_upgrade"
    condition_threshold {
      filter     = "resource.type=\"cloud_function\" AND metric.type=\"logging.googleapis.com/user/info_gke_upgrade\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }
  documentation {
    content = "GKEのアップグレード通知を受信しました。"
    mime_type = "text/markdown"
  }
  notification_channels = [
    google_monitoring_notification_channel.my-mail-address.name,
  ]

  depends_on = [google_logging_metric.info-gke-upgrade]
}

resource "google_monitoring_notification_channel" "my-mail-address" {
  display_name = "アラート通知先"
  type = "email"
  labels = {
    email_address = var.mail_address
  }
}