resource "pagerduty_service" "this" {
  name                    = var.service_name
  auto_resolve_timeout    = 14400
  acknowledgement_timeout = 600
  escalation_policy       = var.escalation_policy_id
}

resource "pagerduty_event_orchestration" "this" {
  name = "${var.service_name} Orchestration"

  set {
    id = "start"

    rule {
      condition {
        expression = "event.summary matches '${var.alert_match}'"
      }

      actions {
        annotate = <<EOT
Troubleshooting Steps:
%{ for step in var.troubleshooting_steps }
- ${step}
%{ endfor }

Escalation:
%{ for esc in var.escalation }
- ${esc}
%{ endfor }

References:
%{ for key, link in var.references }
- ${key}: ${link}
%{ endfor }
EOT
      }
    }
  }
}
