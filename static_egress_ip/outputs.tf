output "vpc_connector" {
  value = google_vpc_access_connector.connector.self_link
}

output "static_ips" {
  description = "List of all static IP addresses used for NAT."
  value       = [for ip in google_compute_address.nat_ips : ip.address]
}