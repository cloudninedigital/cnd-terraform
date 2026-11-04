variable "project" {
  description = "Project ID."
  type = string
}

variable "tagging_server_name" {
  description = "Name of application"
}

variable "preview_server_name" {
  description = "Name of application"
}

variable "container_config_secret_id" {
  description = "key ID of Google Secret manager secret where container configuration ID is stored"
  default = "SGTM_CONTAINER_CONFIG"
}

variable "create_container_config_secret" {
  description = "When true, the module creates the Secret Manager secret container_config_secret_id (empty, without a version). Leave false when the secret already exists. The value is added outside Terraform (gcloud secrets versions add) and must exist before the Cloud Run services are created, so on a first deployment apply the secret first (-target=module.<name>.google_secret_manager_secret.container_config), add the version, then apply the rest. Use one secret ID per workspace when several stages share a project."
  type        = bool
  default     = false
}

variable "container_config_secret_version" {
  description = "version of Google Secret manager secret where container configuration ID is stored"
  default= "latest"
}

variable "preview_server_url" {
  description = "Optional override for preview server URL. If empty, the module uses the created preview service URI."
  default = ""
}

variable "region" {
  description = "Region where function is living"
  default = "europe-west4"
}

variable "max_instance_count" {
  description = "maximum amount of instances"
  default = 6
}

variable "min_instance_count" {
  description = "minimum amount of instances"
  default = 1
}

variable "container_port" {
  description = "port to use for container incoming traffic"
  default = "8080"
}

variable "ingress" {
  description = "Cloud Run ingress setting. Use INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER to only allow traffic via the load balancer."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "enable_startup_probe" {
  description = "When true, replace Cloud Run's default TCP startup probe with an HTTP GET startup probe on health_check_path"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "HTTP path used by the startup probe"
  type        = string
  default     = "/healthz"
}

variable "startup_probe_period_seconds" {
  description = "How often (in seconds) to perform the startup probe"
  type        = number
  default     = 3
}

variable "startup_probe_timeout_seconds" {
  description = "Timeout (in seconds) for each startup probe attempt. Must be < startup_probe_period_seconds."
  type        = number
  default     = 2
}

variable "startup_probe_failure_threshold" {
  description = "Number of consecutive failures before the container is considered failed to start"
  type        = number
  default     = 20
}