#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

terraform {
  required_providers {
    cml2 = {
      source  = "registry.terraform.io/CiscoDevNet/cml2"
      version = "0.9.0-beta3"
    }
    google = {
      source  = "hashicorp/google"
      version = ">=6.17.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3.5"
    }
  }

  required_version = ">= 1.1.0"

  backend "gcs" {
    bucket = "bah-cml-terraform-state"
    prefix = "bah-foundations-lab/state"
  }
}

provider "google" {
  credentials = local.cfg.gcp.credentials
  project     = local.cfg.gcp.project
  region      = local.cfg.gcp.region
  zone        = local.cfg.gcp.zone
}

provider "cml2" {
  address        = "https://becomingahacker.com"
  username       = local.cfg.secrets.app.username
  password       = local.cfg.secrets.app.secret
  skip_verify    = false
  dynamic_config = true
  named_configs  = true

  # optional: inject static headers into every request, e.g. when CML is behind
  # an auth proxy.
  request_headers = {
    Proxy-Authorization = "Bearer ${var.proxy_token}"
  }
}
