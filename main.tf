/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "project_services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 15.0"
  disable_services_on_destroy = var.disable_services_on_destroy

  project_id = var.project_id

  activate_apis = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "config.googleapis.com",
    "documentai.googleapis.com",
    "eventarc.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage.googleapis.com",
  ]
}

data "google_project" "project" {}

resource "google_storage_bucket" "upload_bucket" {
  project                     = module.project_services.project_id
  name                        = "${var.project_id}-upload"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  labels                      = local.resource_labels
}

resource "google_storage_bucket" "archive_bucket" {
  project                     = module.project_services.project_id
  name                        = "${var.project_id}-archive"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  labels                      = local.resource_labels
}

resource "google_storage_bucket" "gcf_source_bucket" {
  project                     = module.project_services.project_id
  name                        = "${var.project_id}-gcf-source-bucket"
  location                    = var.region
  uniform_bucket_level_access = true
  labels                      = local.resource_labels
}

resource "google_storage_bucket_object" "gcf_source_code" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.gcf_source_bucket.name
  source = "./workspace/function-source.zip"
}

resource "google_project_iam_member" "read" {
  project  = module.project_services.project_id
  role     = "roles/editor"
  member   = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    data.google_project.project
  ]
}

resource "google_cloudfunctions2_function" "function" {
  project     = module.project_services.project_id
  name        = local.function_name
  location    = var.region
  description = "Load data from GCS to BQ"
  labels      = local.resource_labels

  build_config {
    runtime     = "python310"
    entry_point = "trigger_gcs" # Set the entry point in the code

    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source_bucket.name
        object = google_storage_bucket_object.gcf_source_code.name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.webhook.email
    environment_variables = {
      DW_PROJECT_ID      = module.project_services.project_id
      GCS_ARCHIVE_BUCKET = google_storage_bucket.archive_bucket.name
    }
  }
}

resource "google_service_account" "webhook" {
  project      = module.project_services.project_id
  account_id   = local.webhook_sa_name
  display_name = "Cloud Functions webhook service account"
}

resource "google_bigquery_dataset" "ecommerce" {
  dataset_id  = "ecommerce"
  description = "Store ecommerce data"
  location    = var.region
  labels      = local.resource_labels
  project     = module.project_services.project_id
}

resource "google_bigquery_table" "order_events" {
  dataset_id          = google_bigquery_dataset.ecommerce.dataset_id
  table_id            = "order_events"
  description         = "Store order events"
  deletion_protection = false
  project             = module.project_services.project_id

  time_partitioning {
    type  = "DAY"
    field = "action_time"
  }

  labels = local.resource_labels

  schema = <<EOF
[
  {
    "name": "order_id",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "customer_email",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "action",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "action_time",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  }
]
EOF

}