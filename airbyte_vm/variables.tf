# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------
variable "project" {
  description = "GCP project that hosts the Airbyte VM and the BigQuery dataset."
  type        = string
}

variable "region" {
  description = "Region for the subnet, Cloud Router/NAT and snapshot storage."
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  description = "Zone for the VM and its disk."
  type        = string
  default     = "europe-west4-a"
}

variable "name" {
  description = "Base name for all resources (VM, SA, network, ...)."
  type        = string
  default     = "airbyte"
}

variable "labels" {
  description = "Labels applied to all labelable resources."
  type        = map(string)
  default     = {}
}

variable "enable_apis" {
  description = "Enable the required Google APIs from this module. Set false if the template already manages APIs."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "create_network" {
  description = "Create a dedicated VPC + subnet. If false, pass network/subnetwork self links."
  type        = bool
  default     = true
}

variable "network" {
  description = "Existing VPC self link/name (only when create_network = false)."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Existing subnet self link/name (only when create_network = false)."
  type        = string
  default     = null
}

variable "subnet_cidr" {
  description = "CIDR for the subnet when create_network = true."
  type        = string
  default     = "10.10.0.0/24"
}

variable "create_nat" {
  description = "Create Cloud Router + Cloud NAT for outbound traffic. Disable if the network already has NAT in this region."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# VM
# ---------------------------------------------------------------------------
variable "machine_type" {
  description = "Airbyte recommends >= 4 vCPU / 8 GB RAM."
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size; holds Docker, the kind cluster, Airbyte's Postgres and Minio."
  type        = number
  default     = 100
}

variable "disk_type" {
  type    = string
  default = "pd-balanced"
}

variable "image" {
  description = "Boot image. The startup script targets Debian/Ubuntu (apt)."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "deletion_protection" {
  type    = bool
  default = true
}

# ---------------------------------------------------------------------------
# Airbyte
# ---------------------------------------------------------------------------
variable "abctl_version" {
  description = "Pin abctl, e.g. \"v0.30.1\". Empty = latest via get.airbyte.com."
  type        = string
  default     = ""
}

variable "airbyte_chart_version" {
  description = "Pin the Airbyte Helm chart passed to `abctl local install --chart-version` (use a 2.x chart for Airbyte >= 2.3). Empty = abctl default (latest)."
  type        = string
  default     = ""
}

variable "insecure_cookies" {
  description = "Pass --insecure-cookies. Needed because the UI is served over plain HTTP through the IAP tunnel."
  type        = bool
  default     = true
}

variable "extra_install_args" {
  description = "Additional args for `abctl local install` (e.g. [\"--values\", \"/opt/airbyte/values.yaml\"])."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Access
# ---------------------------------------------------------------------------
variable "iap_members" {
  description = "Principals allowed to open the IAP tunnel (UI on 8000 + SSH), e.g. [\"group:data@client.nl\", \"user:x@cloudninedigital.nl\"]."
  type        = list(string)
  default     = []
}

variable "manage_iam" {
  description = "Create project-level, IAP and service-account IAM grants. Needs Project IAM Admin + IAP Policy Admin. Set false with only Editor and run the `manual_iam_commands` output instead."
  type        = bool
  default     = true
}

variable "grant_os_login" {
  description = "Also grant roles/compute.osAdminLogin (project level) to iap_members so they can SSH."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BigQuery
# ---------------------------------------------------------------------------
variable "bq_dataset_id" {
  description = "Target dataset for Airbyte raw data."
  type        = string
  default     = "airbyte_raw"
}

variable "create_dataset" {
  description = "Create the dataset in this module. If false, it must already exist."
  type        = bool
  default     = true
}

variable "bq_location" {
  type    = string
  default = "EU"
}

# ---------------------------------------------------------------------------
# Backups
# ---------------------------------------------------------------------------
variable "enable_snapshots" {
  type    = bool
  default = true
}

variable "snapshot_start_time" {
  description = "Daily snapshot start (UTC, HH:00)."
  type        = string
  default     = "02:00"
}

variable "snapshot_retention_days" {
  type    = number
  default = 7
}
