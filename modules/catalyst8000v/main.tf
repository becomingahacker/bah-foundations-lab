#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
}

data "google_compute_zones" "c8k_zones_available" {
  region = var.cfg.gcp.region
}

resource "google_compute_network" "c8k_network" {
  name                    = var.cfg.c8k.network_name
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

data "google_compute_network" "cml_network" {
  name = var.cfg.cml.network_name
}

resource "google_compute_network_peering" "c8k_to_cml_peering" {
  name                 = "c8k-to-cml-peering"
  network              = google_compute_network.c8k_network.self_link
  peer_network         = data.google_compute_network.cml_network.self_link
  stack_type           = "IPV4_IPV6"
  import_custom_routes = true
}

resource "google_compute_network_peering" "cml_to_c8k_peering" {
  name                 = "cml-to-c8k-peering"
  network              = data.google_compute_network.cml_network.self_link
  peer_network         = google_compute_network.c8k_network.self_link
  stack_type           = "IPV4_IPV6"
  export_custom_routes = true
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

data "google_storage_bucket" "bah_machine_images" {
  name = "bah-machine-images"
}

resource "google_storage_bucket_iam_member" "c8k_service_account_storage_iam_member" {
  bucket = data.google_storage_bucket.bah_machine_images.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.c8k_service_account.email}"
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
    src_ip_ranges = ["100.64.5.0/24"]

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
  count        = var.cfg.c8k.instance_count
  name         = "c8k-address-internal-${count.index}"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = google_compute_subnetwork.c8k_subnet.id
  address      = cidrhost(var.cfg.c8k.subnet_cidr, 2 + count.index)
}

resource "google_compute_address" "c8k_address_external" {
  count        = var.cfg.c8k.instance_count
  name         = "c8k-address-external-${count.index}"
  address_type = "EXTERNAL"
}

# TODO cmm - Only IPv4 is supported for stateful configs.  IPv6 is currently ephemeral.
#resource "google_compute_address" "c8k_address_external_v6" {
#  count              = var.cfg.c8k.instance_count
#  name               = "c8k-address-external-v6-${count.index}"
#  address_type       = "EXTERNAL"
#  purpose            = "GCE_ENDPOINT"
#  ip_version         = "IPV6"
#  ipv6_endpoint_type = "VM"
#  subnetwork         = google_compute_subnetwork.c8k_subnet.id
#}

resource "google_compute_region_per_instance_config" "c8k_instance_config" {
  count                         = var.cfg.c8k.instance_count
  region_instance_group_manager = google_compute_region_instance_group_manager.c8k_compute_region_instance_group_manager.name
  name                          = "${var.cfg.c8k.hostname_prefix}-${count.index}"

  preserved_state {
    metadata = {
      # Not user-data, use startup-script
      startup-script = templatefile("${path.module}/templates/c8k_config.tftpl", {
        hostname              = "${var.cfg.c8k.hostname_prefix}-${count.index}"
        loopback_ipv4_address = cidrhost(var.cfg.c8k.loopback_ipv4_prefix, -count.index - 1)
        pod_count             = var.cfg.pod_count
        pod_ipv4_addresses    = google_compute_address.c8k_ipv4_pod_address[*].address
        pod_ipv6_prefixes     = google_compute_address.c8k_ipv6_pod_prefix[*].address
      })
      # Adding a reference to the instance template used causes the stateful instance to update
      # if the instance template changes. Otherwise there is no explicit dependency and template
      # changes may not occur on the stateful instance
      instance_template = google_compute_region_instance_template.c8k_compute_region_instance_template.self_link
    }
    internal_ip {
      interface_name = "nic0"
      ip_address {
        address = google_compute_address.c8k_address_internal[count.index].self_link
      }
    }
    external_ip {
      interface_name = "nic0"
      # Only IPv4 is supported for stateful configs.  IPv6 is ephemeral.
      ip_address {
        address = google_compute_address.c8k_address_external[count.index].self_link
      }
    }
  }
}

resource "google_compute_region_instance_template" "c8k_compute_region_instance_template" {
  name_prefix  = "bahf-c8k"
  machine_type = var.cfg.c8k.machine_type

  resource_manager_tags = {
    (google_tags_tag_key.c8k_tag_network_key.id) = google_tags_tag_value.c8k_tag_network_c8k.id
  }

  disk {
    source_image = var.cfg.c8k.image
    disk_size_gb = var.cfg.c8k.disk_size_gb
  }

  # Use machine as a router & disable source address checking
  can_ip_forward = true

  network_interface {
    network    = google_compute_network.c8k_network.id
    subnetwork = google_compute_subnetwork.c8k_subnet.id
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
    block-project-ssh-keys = try(var.cfg.gcp.ssh_keys != null) ? true : false
    ssh-keys               = try(var.cfg.gcp.ssh_keys != null) ? var.cfg.gcp.ssh_keys : null
    serial-port-enable     = true
  }

  lifecycle {
    create_before_destroy = false
  }

  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }
}

resource "google_compute_region_instance_group_manager" "c8k_compute_region_instance_group_manager" {

  name = "c8k-instance-group-manager"

  base_instance_name = "bahf-c8k"

  distribution_policy_zones        = [for zone in data.google_compute_zones.c8k_zones_available.names : zone]
  distribution_policy_target_shape = "EVEN"

  update_policy {
    type                         = "OPPORTUNISTIC"
    instance_redistribution_type = "NONE"
    minimal_action               = "REPLACE"
    max_unavailable_fixed        = length(data.google_compute_zones.c8k_zones_available.names)
  }

  all_instances_config {
    labels = {
      allow_public_ip_address = "true"
    }
  }

  # TODO cmm - Monitor IP address usage
  stateful_external_ip {
    interface_name = "nic0"
    delete_rule    = "NEVER"
  }

  stateful_internal_ip {
    interface_name = "nic0"
    delete_rule    = "NEVER"
  }

  version {
    instance_template = google_compute_region_instance_template.c8k_compute_region_instance_template.id
  }
}

#resource "google_compute_instance" "c8k_instance" {
#  name                      = "bahf-c8k"               # var.cfg.c8k.hostname #DONE
#  machine_type              = var.cfg.c8k.machine_type #DONE
#  allow_stopping_for_update = true                     #DONE
#
#  labels = { #DONE
#    allow_public_ip_address = "true"
#  }
#
#  params { #DONE
#    resource_manager_tags = {
#      (google_tags_tag_key.c8k_tag_network_key.id) = google_tags_tag_value.c8k_tag_network_c8k.id
#    }
#  }
#
#  boot_disk {
#    initialize_params {
#      image = var.cfg.c8k.image
#      size  = var.cfg.c8k.disk_size_gb
#    }
#  }
#
#  # Use machine as a router & disable source address checking
#  can_ip_forward = true
#
#  network_interface {
#    network    = google_compute_network.c8k_network.id
#    subnetwork = google_compute_subnetwork.c8k_subnet.id
#    network_ip = google_compute_address.c8k_address_internal.address
#
#    access_config {
#      nat_ip = google_compute_address.c8k_address_external.address
#    }
#    ipv6_access_config {
#      network_tier = "PREMIUM"
#    }
#    stack_type = "IPV4_IPV6"
#  }
#
#  service_account {
#    email  = google_service_account.c8k_service_account.email
#    scopes = ["cloud-platform"]
#  }
#
#  metadata = {
#    block-project-ssh-keys = try(var.cfg.gcp.ssh_keys != null) ? true : false
#    ssh-keys               = try(var.cfg.gcp.ssh_keys != null) ? var.cfg.gcp.ssh_keys : null
#    # Not user-data, use startup-script
#    serial-port-enable = true
#  }
#
#  scheduling {
#    preemptible                 = true
#    automatic_restart           = false
#    provisioning_model          = "SPOT"
#    instance_termination_action = "STOP"
#  }
#}

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

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 4
  unhealthy_threshold = 5

  tcp_health_check {
    port = "80"
  }

  log_config {
    enable = true
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
    group          = google_compute_region_instance_group_manager.c8k_compute_region_instance_group_manager.instance_group
    balancing_mode = "CONNECTION"
  }
  connection_draining_timeout_sec = 300

  log_config {
    enable      = true
    sample_rate = 0.05
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

# IPv6 pod forwarding rule - Edge router IPv6 prefix
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

# TODO cmm - ipCollection isn't supported on the IPv6 forwarding rules. 
# https://github.com/hashicorp/terraform-provider-google/issues/18407
# IPv6 pod forwarding rule - Main link IPv6 prefix, BYOIPv6
#resource "google_compute_forwarding_rule" "c8k_forwarding_rule_byoipv6" {
#  count                 = var.cfg.pod_count
#  name                  = "c8k-forwarding-rule-byoipv6-${count.index}"
#  backend_service       = google_compute_region_backend_service.c8k_backend_service.id
#  region                = var.cfg.gcp.region
#  network_tier          = "PREMIUM"
#  ip_version            = "IPV6"
#  ip_protocol           = "L3_DEFAULT"
# TODO cmm - needs count
#  ip_address            = "2602:80a:f004:102::/64"
#  load_balancing_scheme = "EXTERNAL"
#  all_ports             = true
#  ip_collection         = "projects/gcp-asigbahgcp-nprd-47930/regions/us-east1/publicDelegatedPrefixes/nlb-2602-80a-f004-100-56"
#}

data "google_dns_managed_zone" "c8k_zone" {
  name = var.cfg.gcp.dns_zone_name
}

resource "google_dns_record_set" "c8k_dns" {
  count = var.cfg.c8k.instance_count
  name  = "${var.cfg.c8k.hostname_prefix}-${count.index}.${data.google_dns_managed_zone.c8k_zone.dns_name}"
  type  = "A"
  ttl   = 300

  managed_zone = data.google_dns_managed_zone.c8k_zone.name

  rrdatas = [
    google_compute_address.c8k_address_external[count.index].address
  ]
}
