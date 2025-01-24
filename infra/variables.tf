variable "environment" {
  description = "Set the environment"
  type        = string
  validation {
    condition     = var.environment == "dev" || var.environment == "prod"
    error_message = "The 'environment' variable must be 'dev' or 'prod'"
  }
}

variable "my_public_ip" {
  description = "Set your public ip to access via SSH"
  type        = string
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+\\/\\d+$", var.my_public_ip))
    error_message = "The 'your_public_ip' variable must be a valid IPv4 address"
  }
}
