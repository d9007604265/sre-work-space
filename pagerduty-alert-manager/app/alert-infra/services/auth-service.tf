module "auth_service" {
  source               = "../modules/pagerduty_runbook"
  service_name         = "Auth Service"
  escalation_policy_id = var.sre_escalation_policy_id
  alert_match          = "AuthServiceErrors"

  troubleshooting_steps = [
    "Check pod logs: kubectl logs <pod> -n auth-service",
    "Verify OIDC provider health",
    "Check Redis cache connectivity",
    "Check error rate in Grafana"
  ]

  escalation = [
    "Identity team if OIDC down",
    "Platform team if Redis unreachable"
  ]

  references = {
    "Grafana Dashboard" = "https://grafana.company.com/d/auth-service"
    "Runbook"           = "https://wiki.company.com/auth-service/runbook"
  }
}
