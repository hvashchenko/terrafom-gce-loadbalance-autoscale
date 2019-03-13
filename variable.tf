variable "startup_script_ubuntu" {
  default = <<EOF
#! /bin/bash
apt-get update
apt-get install -y apache2
cat <<EOF > /var/www/html/index.html
<html><body><h1>Hello World</h1>
<p>This page was created from a simple startup script in ubuntu!</p>
</body></html>
EOF
}
variable "startup_script_debian" {
default = <<EOF
#! /bin/bash
apt-get update
apt-get install -y apache2
sudo mkdir /var/www/html/video
echo '<!doctype html><html><body><h1>www-video</h1></body></html>' | sudo tee /var/www/html/video/index.html
cat <<EOF > /var/www/html/index.html
<html><body><h1>Hello World</h1>
<p>This page was created from a simple startup script in debian!</p>
</body></html>
EOF
}
variable "startup_script_centos7" {
default = <<EOF
#! /bin/bash
sudo yum -y update
sudo yum  install -y httpd
sudo mkdir /var/www/html/audio
echo '<!doctype html><html><body><h1>www-audio</h1></body></html>' | sudo tee /var/www/html/audio/index.html
cat <<EOF > /var/www/html/index.html
<html><body><h1>Hello World</h1>
<p>This page was created from a simple startup script in Centos7!</p>
</body></html>
EOF
}
variable "ssh_keys" {
  description = "SSH Private Key"
  default     = "~/.ssh/google_compute_engine"
}

