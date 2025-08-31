module "payments_api" {
  source               = "../modules/pagerduty_runbook"
  service_name         = "Payments API"
  escalation_policy_id = var.sre_escalation_policy_id
  alert_match          = "PaymentsApiHighLatency"

  troubleshooting_steps = [
    "Check pod health: kubectl get pods -n payments-api",
    "Check logs: kubectl logs <pod> -n payments-api",
    "Verify DB connection: kubectl exec -it <pod> -- nc -vz db 5432",
    "Check RDS metrics in CloudWatch"
  ]

  escalation = [
    "DB team if DB is unhealthy",
    "App team if pods are crashlooping"
  ]

  references = {
    "Grafana Dashboard" = "https://grafana.company.com/d/payments-api"
    "Architecture Doc"  = "https://wiki.company.com/payments-api"
  }
}
