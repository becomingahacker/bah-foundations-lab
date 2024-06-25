#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  c8k_startup_script = templatefile("${path.module}/templates/c8k_config.tftpl", {
    cfg                = var.cfg
    pod_ipv4_addresses = google_compute_address.c8k_ipv4_pod_address[*].address
    pod_ipv6_prefixes  = google_compute_address.c8k_ipv6_pod_prefix[*].address
  })
}

resource "google_compute_network" "c8k_network" {
  name                    = "c8k-network"
  auto_create_subnetworks = false
  mtu                     = 8896
}

resource "google_compute_subnetwork" "c8k_subnet" {
  name             = var.cfg.c8k.subnet_name
  network          = google_compute_network.c8k_network.id
  ip_cidr_range    = var.cfg.c8k.subnet_cidr
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"

  #log_config {
  #  aggregation_interval = "INTERVAL_5_SEC"
  #  flow_sampling        = 0.5
  #  metadata             = "INCLUDE_ALL_METADATA"
  #  metadata_fields      = []
  #}
}

resource "google_tags_tag_key" "c8k_tag_network_key" {
  parent      = "projects/${var.cfg.gcp.project}"
  short_name  = "C8K Network"
  description = "For identifying C8K Network resources"
  purpose     = "GCE_FIREWALL"
  purpose_data = {
    network = "${var.cfg.gcp.project}/${google_compute_network.c8k_network.name}"
  }
}

resource "google_tags_tag_value" "c8k_tag_network_c8k" {
  parent      = "tagKeys/${google_tags_tag_key.c8k_tag_network_key.name}"
  short_name  = "c8k"
  description = "For identifying Catalyst 8000v instances"
}

resource "google_service_account" "c8k_service_account" {
  account_id   = var.cfg.c8k.service_account_id
  display_name = var.cfg.c8k.service_account_display_name
}

resource "google_project_iam_member" "c8k_service_account_iam_member" {
  project = var.cfg.gcp.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.c8k_service_account.email}"
}

resource "google_compute_region_network_firewall_policy" "c8k_firewall_policy" {
  name   = "c8k-firewall-policy"
  region = var.cfg.gcp.region
}

resource "google_compute_region_network_firewall_policy_association" "c8k_firewall_policy_association" {
  name              = "c8k-firewall-policy-association"
  attachment_target = google_compute_network.c8k_network.id
  firewall_policy   = google_compute_region_network_firewall_policy.c8k_firewall_policy.id
  project           = var.cfg.gcp.project
  region            = var.cfg.gcp.region
}

resource "google_network_security_address_group" "c8k_allowed_subnets_address_group" {
  name        = "c8k-allowed-subnets"
  parent      = "projects/${var.cfg.gcp.project}"
  description = "Becoming a Hacker address group to filter on sources"
  location    = var.cfg.gcp.region
  items       = var.cfg.c8k.allowed_ipv4_subnets
  type        = "IPV4"
  capacity    = 100
}

resource "google_compute_region_network_firewall_policy_rule" "c8k_firewall_rule_icmp" {
  action          = "allow"
  description     = "C8K allow ICMP from any to any"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  firewall_policy = google_compute_region_network_firewall_policy.c8k_firewall_policy.id
  priority        = 10
  region          = var.cfg.gcp.region
  rule_name       = "c8k-firewall-rule-icmp"

  match {
    src_ip_ranges = ["0.0.0.0/0"]

    layer4_configs {
      ip_protocol = "icmp"
    }
  }
}

resource "google_compute_region_network_firewall_policy_rule" "c8k_firewall_rule_icmpv6" {
  action          = "allow"
  description     = "Cisco Modeling Labs allow ICMPv6 from any to any"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  firewall_policy = google_compute_region_network_firewall_policy.c8k_firewall_policy.id
  priority        = 11
  region          = var.cfg.gcp.region
  rule_name       = "c8k-firewall-rule-icmpv6"

  match {
    src_ip_ranges = ["::/0"]

    layer4_configs {
      # ipv6-icmp, requires numeric protocol
      # https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
      ip_protocol = 58
    }
  }
}

resource "google_compute_region_network_firewall_policy_rule" "c8k_firewall_rule_ssh" {
  action          = "allow"
  description     = "C8K allow SSH from allowed subnets"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  firewall_policy = google_compute_region_network_firewall_policy.c8k_firewall_policy.id
  priority        = 101
  region          = var.cfg.gcp.region
  rule_name       = "c8k-firewall-rule-ssh"

  match {
    src_address_groups = [google_network_security_address_group.c8k_allowed_subnets_address_group.id]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["22"]
    }
  }

  target_service_accounts = [google_service_account.c8k_service_account.email]
}

resource "google_compute_region_network_firewall_policy_rule" "c8k_firewall_rule_gre" {
  action          = "allow"
  description     = "C8K allow GRE from CML controller"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  firewall_policy = google_compute_region_network_firewall_policy.c8k_firewall_policy.id
  priority        = 102
  region          = var.cfg.gcp.region
  rule_name       = "c8k-firewall-rule-gre"

  match {
    src_ip_ranges = ["100.64.1.0/24"]

    layer4_configs {
      ip_protocol = 47
    }
  }

  target_service_accounts = [google_service_account.c8k_service_account.email]
}

resource "google_compute_region_network_firewall_policy_rule" "c8k_firewall_rule_pods_v4" {
  action          = "allow"
  description     = "C8K allow IPv4 from any to pod IPs"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  firewall_policy = google_compute_region_network_firewall_policy.c8k_firewall_policy.id
  priority        = 103
  region          = var.cfg.gcp.region
  rule_name       = "c8k-firewall-rule-pods-v4"

  match {

    src_ip_ranges = ["0.0.0.0/0"]

    dest_ip_ranges = [for addr in google_compute_address.c8k_ipv4_pod_address : "${addr.address}/32"]
    layer4_configs {
      ip_protocol = "all"
    }
  }

  target_service_accounts = [google_service_account.c8k_service_account.email]
}

resource "google_compute_region_network_firewall_policy_rule" "c8k_firewall_rule_pods_v6" {
  action          = "allow"
  description     = "C8K allow IPv6 from any to pod prefixes"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  firewall_policy = google_compute_region_network_firewall_policy.c8k_firewall_policy.id
  priority        = 104
  region          = var.cfg.gcp.region
  rule_name       = "c8k-firewall-rule-pods-v6"

  match {

    src_ip_ranges = ["::/0"]

    dest_ip_ranges = [for prefix in google_compute_address.c8k_ipv6_pod_prefix : "${prefix.address}/96"]
    layer4_configs {
      ip_protocol = "all"
    }
  }

  target_service_accounts = [google_service_account.c8k_service_account.email]
}

resource "google_compute_address" "c8k_address_internal" {
  name         = "c8k-address-internal"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = google_compute_subnetwork.c8k_subnet.id
  address      = "100.64.2.2"
}

resource "google_compute_address" "c8k_address_external" {
  name         = "c8k-address-external"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "c8k_instance" {
  name                      = "bahf-c8k" # var.cfg.c8k.hostname
  machine_type              = var.cfg.c8k.machine_type
  allow_stopping_for_update = true

  params {
    resource_manager_tags = {
      (google_tags_tag_key.c8k_tag_network_key.id) = google_tags_tag_value.c8k_tag_network_c8k.id
    }
  }

  boot_disk {
    initialize_params {
      image = var.cfg.c8k.image
      size  = var.cfg.c8k.disk_size_gb
    }
  }

  # Use machine as a router & disable source address checking
  can_ip_forward = true

  network_interface {
    network    = google_compute_network.c8k_network.id
    subnetwork = google_compute_subnetwork.c8k_subnet.id
    network_ip = google_compute_address.c8k_address_internal.address

    access_config {
      nat_ip = google_compute_address.c8k_address_external.address
    }
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
    stack_type = "IPV4_IPV6"
  }

  service_account {
    email  = google_service_account.c8k_service_account.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    block-project-ssh-keys = true
    block-project-ssh-keys = try(var.cfg.gcp.ssh_keys != null) ? true : false
    ssh-keys = try(var.cfg.gcp.ssh_keys != null) ? var.cfg.gcp.ssh_keys : null
    # Not user-data, use startup-script
    startup-script     = local.c8k_startup_script
    serial-port-enable = true
  }
}

resource "google_compute_network_endpoint_group" "c8k_network_endpoint_group" {
  name                  = "c8k-lb-neg"
  network               = google_compute_network.c8k_network.id
  subnetwork            = google_compute_subnetwork.c8k_subnet.id
  zone                  = var.cfg.gcp.zone
  network_endpoint_type = "GCE_VM_IP"
}

resource "google_compute_network_endpoint" "c8k_network_endpoint" {
  network_endpoint_group = google_compute_network_endpoint_group.c8k_network_endpoint_group.name

  instance   = google_compute_instance.c8k_instance.name
  ip_address = google_compute_instance.c8k_instance.network_interface[0].network_ip
}

resource "google_compute_address" "c8k_ipv4_pod_address" {
  count        = var.cfg.pod_count
  name         = "c8k-ipv4-pod-address-${count.index}"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "c8k_ipv6_pod_prefix" {
  count              = var.cfg.pod_count
  name               = "c8k-ipv6-pod-prefix-${count.index}"
  address_type       = "EXTERNAL"
  ip_version         = "IPV6"
  ipv6_endpoint_type = "NETLB"
  prefix_length      = 96
  subnetwork         = google_compute_subnetwork.c8k_subnet.id
}

resource "google_compute_region_health_check" "c8k_tcp_port_80_health_check" {
  name = "c8k-tcp-port-80-health-check"

  timeout_sec         = 1
  check_interval_sec  = 5
  healthy_threshold   = 4
  unhealthy_threshold = 5

  tcp_health_check {
    port = "80"
  }

  log_config {
    enable = false
  }
}

# backend service
resource "google_compute_region_backend_service" "c8k_backend_service" {
  name                  = "c8k-backend-service"
  health_checks         = [google_compute_region_health_check.c8k_tcp_port_80_health_check.id]
  load_balancing_scheme = "EXTERNAL"
  locality_lb_policy    = "MAGLEV"
  protocol              = "UNSPECIFIED"
  session_affinity      = "CLIENT_IP"
  region                = var.cfg.gcp.region

  backend {
    group          = google_compute_network_endpoint_group.c8k_network_endpoint_group.id
    balancing_mode = "CONNECTION"
  }
  connection_draining_timeout_sec = 300

  log_config {
    enable = false
  }
}

# IPv4 pod forwarding rule
resource "google_compute_forwarding_rule" "c8k_forwarding_rule_v4" {
  count                 = var.cfg.pod_count
  name                  = "c8k-forwarding-rule-ipv4-${count.index}"
  backend_service       = google_compute_region_backend_service.c8k_backend_service.id
  region                = var.cfg.gcp.region
  network_tier          = "PREMIUM"
  ip_version            = "IPV4"
  ip_protocol           = "L3_DEFAULT"
  ip_address            = google_compute_address.c8k_ipv4_pod_address[count.index].address
  load_balancing_scheme = "EXTERNAL"
  all_ports             = true
  #subnetwork            = google_compute_subnetwork.c8k_subnet.id
}

# IPv6 pod forwarding rule
resource "google_compute_forwarding_rule" "c8k_forwarding_rule_v6" {
  count                 = var.cfg.pod_count
  name                  = "c8k-forwarding-rule-ipv6-${count.index}"
  backend_service       = google_compute_region_backend_service.c8k_backend_service.id
  region                = var.cfg.gcp.region
  network_tier          = "PREMIUM"
  ip_version            = "IPV6"
  ip_protocol           = "L3_DEFAULT"
  ip_address            = google_compute_address.c8k_ipv6_pod_prefix[count.index].id
  subnetwork            = google_compute_subnetwork.c8k_subnet.id
  load_balancing_scheme = "EXTERNAL"
  all_ports             = true
}
