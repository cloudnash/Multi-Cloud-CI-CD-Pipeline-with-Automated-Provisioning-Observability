terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ---------- Networking ----------
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

# ---------- Least-privilege service account for GKE nodes ----------
resource "google_service_account" "gke_node" {
  account_id   = "${var.project_name}-${var.environment}-gke-node"
  display_name = "GKE node service account (${var.environment})"
}

resource "google_project_iam_member" "gke_node_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_project_iam_member" "gke_node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

# ---------- GKE Cluster ----------
resource "google_container_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"
  location = var.region

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.main.id

  # Manage node pools separately from the default pool
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "main" {
  name       = "${var.project_name}-${var.environment}-pool"
  location   = var.region
  cluster    = google_container_cluster.main.name
  node_count = var.desired_node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    machine_type    = var.machine_type
    service_account = google_service_account.gke_node.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
