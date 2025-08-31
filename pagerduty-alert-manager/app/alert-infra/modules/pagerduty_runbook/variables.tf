variable "service_name" { type = string }
variable "escalation_policy_id" { type = string }
variable "alert_match" { type = string }
variable "troubleshooting_steps" { type = list(string) }
variable "escalation" { type = list(string) }
variable "references" { type = map(string) }
