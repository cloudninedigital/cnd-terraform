output "vpc_connector" {
  value = google_vpc_access_connector.connector.self_link
}

output "static_ip" {
  value = google_compute_address.address.address
}