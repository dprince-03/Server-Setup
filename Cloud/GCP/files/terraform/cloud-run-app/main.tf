# Cloud Run app starter: Artifact Registry + runtime SA + Secret Manager secret (value added by a human) +
# Cloud Run v2 service + Workload Identity Federation so GitHub Actions can deploy without keys.
terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
  backend "gcs" {} # terraform init -backend-config="bucket=..." -backend-config="prefix=..."
}

variable "project_id" { type = string }
variable "region" {
  type    = string
  default = "europe-west1"
}
variable "name" {
  type    = string
  default = "myapp"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "github_repo" {
  description = "owner/repo allowed to deploy"
  type        = string
}
variable "allow_public" {
  description = "Allow unauthenticated invocations (public website/API)"
  type        = bool
  default     = true
}

provider "google" {
  project        = var.project_id
  region         = var.region
  default_labels = { app = var.name, env = var.env, managed-by = "terraform" }
}

data "google_project" "this" {}

# ---------------- APIs ----------------
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com", "artifactregistry.googleapis.com", "secretmanager.googleapis.com",
    "iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# ---------------- Registry ----------------
resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = var.name
  format        = "DOCKER"
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions { keep_count = 30 }
  }
  depends_on = [google_project_service.apis]
}

# ---------------- Runtime identity ----------------
resource "google_service_account" "runtime" {
  account_id   = "${var.name}-runtime"
  display_name = "${var.name} Cloud Run runtime"
}

# ---------------- Secret (container only: a human adds the value) ----------------
resource "google_secret_manager_secret" "api_key" {
  secret_id = "${var.name}-api-key"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_iam_member" "runtime_access" {
  secret_id = google_secret_manager_secret.api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

# ---------------- Cloud Run ----------------
resource "google_cloud_run_v2_service" "app" {
  name     = var.name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.runtime.email
    scaling {
      min_instance_count = var.env == "prod" ? 1 : 0
      max_instance_count = 20
    }
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello" # placeholder; CI deploys the real image
      ports { container_port = 8080 }
      resources {
        limits            = { cpu = "1", memory = "512Mi" }
        cpu_idle          = true
        startup_cpu_boost = true
      }
      env {
        name  = "APP_ENV"
        value = var.env
      }
      # Uncomment AFTER adding a secret version (gcloud secrets versions add ... --data-file=-):
      # env {
      #   name = "API_KEY"
      #   value_source {
      #     secret_key_ref {
      #       secret  = google_secret_manager_secret.api_key.secret_id
      #       version = "latest"
      #     }
      #   }
      # }
      startup_probe {
        http_get { path = "/" }
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0].image, client, client_version] # CI owns the image
  }
  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  count    = var.allow_public ? 1 : 0
  name     = google_cloud_run_v2_service.app.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ---------------- GitHub → GCP via Workload Identity Federation ----------------
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  # Only this repository may use the pool
  attribute_condition = "assertion.repository == \"${var.github_repo}\""
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deployer" {
  account_id   = "${var.name}-deployer"
  display_name = "${var.name} GitHub deployer"
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

resource "google_project_iam_member" "deployer_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_artifact_registry_repository_iam_member" "deployer_push" {
  location   = var.region
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

# The deployer may deploy revisions that run as the runtime SA (and only that SA)
resource "google_service_account_iam_member" "deployer_actas_runtime" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}

# ---------------- Outputs (references, not secrets) ----------------
output "service_url" { value = google_cloud_run_v2_service.app.uri }
output "GCP_WIF_PROVIDER" { value = google_iam_workload_identity_pool_provider.github.name }
output "GCP_DEPLOY_SA" { value = google_service_account.deployer.email }
output "GAR_REPO" { value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}" }
output "secret_id" { value = google_secret_manager_secret.api_key.secret_id }
