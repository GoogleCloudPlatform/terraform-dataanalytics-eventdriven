# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "random_id" "unique_id" {
  byte_length = 3
}

locals {
  function_name = "gcs-to-bq-trigger"
  resource_labels = merge(var.resource_labels, {
    deployed_by = "cloudbuild"
    repo        = "click-to-deploy-solutions"
    solution    = "gcs-to-bq-trigger"
    terraform   = "true"
  })
  webhook_sa_name = var.unique_names ? "bt-webhook-sa-${random_id.unique_id.hex}" : "gcs-to-bq-trigger-webhook-sa"
  trigger_name    = var.unique_names ? "bt-trigger-${random_id.unique_id.hex}" : "gcs-to-bq-trigger-trigger"
  trigger_sa_name = var.unique_names ? "bt-trigger-sa-${random_id.unique_id.hex}" : "gcs-to-bq-trigger-trigger-sa"
}

# ID of the project in which you want to deploy the solution
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

#Defines the deployment region for cloud resources.
variable "region" {
  type        = string
  description = "GCP region"
}

#Assigns a label to provisioned cloud resources
variable "resource_labels" {
  type        = map(string)
  description = "Resource labels"
  default     = {}
}

variable "disable_services_on_destroy" {
  description = "Whether project services will be disabled when the resources are destroyed."
  type        = bool
  default     = false
}

# Used for testing.
variable "unique_names" {
  description = "Whether to use unique names for resources"
  type        = bool
  default     = false
}
