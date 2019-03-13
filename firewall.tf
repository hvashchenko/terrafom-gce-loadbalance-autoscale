resource "google_compute_firewall" "allow_ssh_office" {  
    name = "allow-ssh"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["22"]
    }

    source_ranges = ["38.88.232.58/32"]
}

resource "google_compute_firewall" "allow_http" {
    name = "allow-http"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["80", "443"]
    }

    source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
    target_tags = ["http-tag"]
}
