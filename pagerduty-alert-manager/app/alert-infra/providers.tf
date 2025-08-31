terraform {
  required_providers {
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "~> 2.20"
    }
  }
  backend "s3" {}
}

provider "pagerduty" {
  token = var.pagerduty_token
}
