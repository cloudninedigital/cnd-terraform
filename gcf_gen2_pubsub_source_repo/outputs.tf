# Output function name so it can be referenced by other modules
output "function_name" {
  value = google_cloudfunctions2_function.function.name
}
