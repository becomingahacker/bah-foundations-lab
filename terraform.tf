#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

terraform {
  required_providers {
    cml2 = {
      source  = "CiscoDevNet/cml2"
      version = "~>0.8.0"
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
  address        = "https://cml-controller.becomingahacker.com"
  username       = local.cfg.secrets.app.username
  password       = local.cfg.secrets.app.secret
  skip_verify    = true
  dynamic_config = true
}
