variable "pagerduty_token" {
  type        = string
  description = "PagerDuty API token"
  sensitive   = true
}

variable "sre_escalation_policy_id" {
  type        = string
  description = "Escalation policy ID for SRE team"
}
