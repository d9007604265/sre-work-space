output "pagerduty_services" {
  value = {
    payments_api = module.payments_api.service_id
    auth_service = module.auth_service.service_id
  }
}
