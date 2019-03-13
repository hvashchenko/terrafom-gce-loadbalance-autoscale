resource "google_compute_instance" "ubuntu-trusty" {
   name = "ubuntu-trusty"
   machine_type = "n1-standard-2"
   zone = "us-west1-a"
   tags = ["http-tag"]
   boot_disk {
      initialize_params {
      image = "ubuntu-1404-lts"
      size = "30"
   }
   auto_delete = true
}

network_interface {
   network = "default"
   access_config {}
}

metadata_startup_script = "${var.startup_script_ubuntu}"

metadata {
    sshKeys = "${file("${var.ssh_keys}")}"
  }

service_account {
   scopes = ["userinfo-email", "compute-ro", "storage-ro"]
   }

}

resource "google_compute_instance" "debian9" {
   name = "debian9"
   machine_type = "g1-small"
   zone = "us-west1-a"
   tags = ["http-tag"] 
   boot_disk {
      initialize_params {
      image = "debian-cloud/debian-9"
      size = "10"
   }
   auto_delete = true
}
network_interface {
    network = "default"
    access_config { }
}
service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
metadata_startup_script = "${var.startup_script_debian}"
metadata {
    sshKeys = "${file("${var.ssh_keys}")}"
}
}
resource "google_compute_instance_template" "centos7" {
    name = "centos7"
    machine_type = "g1-small"
    
    tags = ["cen", "tos"]
    can_ip_forward = false
    disk {
    source_image = "centos-cloud/centos-7"
    auto_delete = true
    disk_size_gb = 20
    boot = true
  }
          
network_interface { 
    network = "default"
    access_config { }
}         
service_account {       
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
metadata {
     cen = "tos7"
     sshKeys = "${file("${var.ssh_keys}")}"
 }
metadata_startup_script = "${var.startup_script_centos7}"
}

resource "google_compute_global_address" "external-address" {
  name = "tf-external-address"
}

resource "google_compute_instance_group" "www-resources" {
  name = "tf-www-resources"
  zone = "us-west1-a"
  
  instances = ["${google_compute_instance.ubuntu-trusty.self_link}"]

  named_port {
    name = "http"
    port = "80"
  }
}

resource "google_compute_instance_group" "video-resources" {
  name = "tf-video-resources"
  zone = "us-west1-a"
  instances = ["${google_compute_instance.debian9.self_link}"]

  named_port {
    name = "http"
    port = "80"
  }
}
resource "google_compute_target_pool" "centos7"{
  name = "my-target-pool"
  
}
resource "google_compute_instance_group_manager" "centos7" {
  name = "my-cgm"
  zone = "us-central1-f"

  instance_template  = "${google_compute_instance_template.centos7.self_link}"

  target_pools       = ["${google_compute_target_pool.centos7.self_link}"]
  base_instance_name = "centos7"
}
resource "google_compute_autoscaler" "centos7" {
    name = "autoscaler"
    zone = "us-central1-f"
    target = "${google_compute_instance_group_manager.centos7.self_link}"

    autoscaling_policy {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
    
}
}

resource "google_compute_health_check" "health-check" {
  name = "tf-health-check"
  timeout_sec = 1
  http_health_check {}
}

resource "google_compute_backend_service" "www-service" {
  name     = "tf-www-service"
  protocol = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.www-resources.self_link}"
  }

  health_checks = ["${google_compute_health_check.health-check.self_link}"]
}

resource "google_compute_backend_service" "video-service" {
  name     = "tf-video-service"
  protocol = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.video-resources.self_link}"
  }

  health_checks = ["${google_compute_health_check.health-check.self_link}"]
}



resource "google_compute_url_map" "web-map" {
  name            = "tf-web-map"
  default_service = "${google_compute_backend_service.www-service.self_link}"

  host_rule {
    hosts        = ["*"]
    path_matcher = "tf-allpaths"
  }

  path_matcher {
    name            = "tf-allpaths"
    default_service = "${google_compute_backend_service.www-service.self_link}"

    path_rule {
      paths   = ["/video", "/video/*"]
      service = "${google_compute_backend_service.video-service.self_link}"
    }      
  }
}

resource "google_compute_target_http_proxy" "http-lb-proxy" {
  name    = "tf-http-lb-proxy"
  url_map = "${google_compute_url_map.web-map.self_link}"
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "tf-http-content-gfr"
  target     = "${google_compute_target_http_proxy.http-lb-proxy.self_link}"
  ip_address = "${google_compute_global_address.external-address.address}"
  port_range = "80"
}






