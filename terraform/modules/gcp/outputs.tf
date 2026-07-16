output "cluster_name" {
  value = google_container_cluster.main.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.main.endpoint
  sensitive = true
}

output "vpc_id" {
  value = google_compute_network.main.id
}
