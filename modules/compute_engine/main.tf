resource "google_compute_instance_template" "instance-template-terraform-ffg-3" {
  name_prefix  = "instance-template-terraform-ffg-3"
  description = "This is used to create instance template."

  tags = ["project", "terraform-gcp-project-ffg-3"]

  labels = {
    environment = "dev"
    project = "terraform-gcp-project-ffg-3"
  }

  machine_type = "e2-micro"
  region       = var.gcp_region
  can_ip_forward = true

  disk {
    source_image      = "ubuntu-os-cloud/ubuntu-1604-lts"
    auto_delete       = true
    boot              = true
    resource_policies = [google_compute_resource_policy.daily_backup.id]
  }

  network_interface {
    network = "default"
    access_config {}
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "instance-group-manager"
  version {
    instance_template  = google_compute_instance_template.instance-template-terraform-ffg-3.id
  }
  base_instance_name = "instance-group-manager"
  zone               = var.gcp_zone
  target_size        = "3"

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "autoscaler"
  zone   = var.gcp_zone
  target = google_compute_instance_group_manager.instance_group_manager.id

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 3
    cooldown_period = 60
    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 3
  timeout_sec         = 3
  healthy_threshold   = 3
  unhealthy_threshold = 3

  http_health_check {
    request_path = "/healthcheck"
    port         = "8080"
  }
}

resource "google_compute_resource_policy" "daily_backup" {
  name   = "every-day-2am"
  region = var.gcp_region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "02:00"
      }
    }
  }
}