output "ip_address" {
  description = "IP address of the load balancer (primary ip_version). Point the domain's DNS record at it: an A record for IPV4, an AAAA record for IPV6."
  value       = google_compute_global_forwarding_rule.https_forwarding_rule.ip_address
}

output "secondary_ip_address" {
  description = "IP address on the other IP version when enable_dual_stack = true (null otherwise). Add it as the second DNS record (A or AAAA)."
  value       = var.enable_dual_stack ? google_compute_global_forwarding_rule.https_forwarding_rule_secondary[0].ip_address : null
}

output "domains" {
  description = "Domains on the managed SSL certificate. The certificate only becomes ACTIVE once each domain resolves to the load balancer."
  value       = local.all_domains
}
