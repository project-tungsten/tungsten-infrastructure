variable "aws_access_key" {}
variable "aws_secret_key" {}
// CentOS Linux 7 x86_64 HVM EBS 1704_01
variable "aws_ami" { default = "ami-d52f5bc3" }
variable "ssh_public_key_path" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

resource "aws_key_pair" "terraform" {
  public_key = "${file("${var.ssh_public_key_path}")}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tungsten-k8s-master-server-1" {
  ami           = "${var.aws_ami}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.terraform.id}"
  security_groups = ["allow_all"]
  tags {
    "kargo-kube-master" = "true"
  }
}

resource "aws_instance" "tungsten-etcd-server-1" {
  ami           = "${var.aws_ami}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.terraform.id}"
  security_groups = ["allow_all"]
  tags {
    "kargo-etcd" = "true"
  }
}

resource "aws_instance" "tungsten-etcd-server-2" {
  ami           = "${var.aws_ami}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.terraform.id}"
  security_groups = ["allow_all"]
  tags {
    "kargo-etcd" = "true"
  }
}

resource "aws_instance" "tungsten-k8s-worker-server-1" {
  ami           = "${var.aws_ami}"
  instance_type = "t2.large"
  key_name = "${aws_key_pair.terraform.id}"
  security_groups = ["allow_all"]
  tags {
    "kargo-kube-node" = "true"
  }
}

resource "aws_instance" "tungsten-k8s-worker-server-2" {
  ami           = "${var.aws_ami}"
  instance_type = "t2.large"
  key_name = "${aws_key_pair.terraform.id}"
  security_groups = ["allow_all"]
  tags {
    "kargo-kube-node" = "true"
  }
}

resource "aws_route53_zone" "primary" {
  name = "project-tungsten.com"
}

resource "aws_route53_record" "k8s-api" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "k8s-api.project-tungsten.com"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.tungsten-k8s-master-server-1.public_ip}"]
}