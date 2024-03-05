output "email" {
  value = google_service_account.account.email
}

output "roles" {
  value = [for role in google_project_iam_member.roles : role.role]
}