variable "log_group_name" {}
variable "retention_in_days" {}
variable "kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}