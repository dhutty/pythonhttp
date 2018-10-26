terraform {
  required_version = ">= 0.10.1, < 0.12"
  backend "s3" {
    bucket = "tf-state-lisa18"
    key    = "tfstate/pythonhttp/terraform.state"
    region = "us-east-1"
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "namespace" {
  default = "lisa18"
}

variable "zone" {
  default = {
    name    = "hutty.uk"
    aws_id  = "ZZTGW38H01AUD"
  }
}

variable "ssh_pub_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5BIG3TyFC0gWa4dxR2BfuFdsw8TZzXRjOOXuoRIR2oOOqtDB4/IffHliMg2QE3AR7FdduRkP7amRvWB7xjVBmLDOJBDxycdUOub3pIJW5ha5x2DJPddKBVgxU2TyDkssaGevJ3eWUclZ1EXyY2ORX9GS9rtvTi4yCoJ978zH9DSBy2l2LZnQCS+ViTP/L4IhEHGq3aHIrrd+YsY5r4VEEdI36cFa28Kcafue4fzlHj+m6QlPISjH8oymZy6eKMRUXfQRjDtOzWrs+lQ4kJkHkZu6Z4qDzOT1oQuanwVA5SyWXKWg4xatQMHTaVDuxEYeRzIKe1x3f9whBHy651o6H dhutty@allgoodbits.org"
}

variable "ami" {
  # both from 20180810
  # Amazon Linux 2 HVM 64-bit EBS backend:
  default = "ami-00b94673edfccb7ca"
  # Alternatively: Amazon Linux 2 minimal  HVM 64-bit EBS backend: ami-0f686c64c5fb9828c
}

variable "ssh_user" {
  # For Amazon Linux
  default = "ec2-user"
}

variable "ssh_private_key_path" {
  description = "the path to the private ssh key, perhaps: export TF_VAR_ssh_private_key_path=${HOME}/.ssh/foo.rsa"
}

variable "instance_type" {
  default = "t2.micro"
}

output "instance_public_ip" {
	value = "${aws_instance.pythonhttp.public_ip}"
}

output "target_url" {
  value ="pythonhttp.${var.namespace}.${var.zone["name"]}"
}

provider "aws" {
  version = "~> 1.36"
  region = "${var.aws_region}"
}

data terraform_remote_state "infra" {
  backend = "s3"
  config {
    bucket = "tf-state-lisa18"
    key    = "tfstate/giant/terraform.state"
    region = "us-east-1"
  }
}

resource "aws_key_pair" "dhutty" {
  key_name   = "dhutty-key"
  public_key = "${var.ssh_pub_key}" ## the only required attribute
}

resource "aws_instance" "pythonhttp" {
  ami = "${var.ami}" ## the only required attribute
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.dhutty.key_name}"
  subnet_id =  "${data.terraform_remote_state.infra.public_subnet_ids[0]}"
  vpc_security_group_ids =  [ "${data.terraform_remote_state.infra.security_group_ids}" ]
  provisioner "remote-exec" {
    inline = [ 
      "sudo yum install -y busybox python3 git",
			"git clone https://github.com/dhutty/pythonhttp",
			"nohup python3 pythonhttp/pythonhttpserver.py --host 0.0.0.0 &"
    ]
		connection {
			type        = "ssh"
			private_key = "${file(var.ssh_private_key_path)}"
			user        = "${var.ssh_user}"
			host        =  "${aws_instance.pythonhttp.public_ip}"
		}
  } 
}

resource "aws_alb_target_group" "vm" {
  name        = "${var.namespace != "" ? "${var.namespace}-" : ""}pythonhttp-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "${data.terraform_remote_state.infra.vpc_id}"
  target_type = "ip"

  health_check {
    healthy_threshold   = "2"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/healthcheck"
    unhealthy_threshold = "2"
  }

}

resource "aws_alb_target_group_attachment" "pythonhttp" {
  target_group_arn = "${aws_alb_target_group.vm.arn}"
  target_id        = "${aws_instance.pythonhttp.private_ip}"
  port             = 8080
}

resource "aws_alb_listener_rule" "vm_listener_rule" {
  listener_arn =  "${data.terraform_remote_state.infra.alb_listener_arn}"
  priority     = 98

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.vm.arn}"
  }

  condition {
    field  = "host-header"
    values = ["pythonhttp.${var.namespace != "" ? "${var.namespace}." : ""}${var.zone["name"]}"]
  }
}
resource "aws_route53_record" "pythonhttp" {
  zone_id = "${data.terraform_remote_state.infra.zone_id}"
  name = "pythonhttp.${var.namespace != "" ? "${var.namespace}." : ""}${var.zone["name"]}"
  type    = "CNAME"
  ttl     = "30"
  records = ["${data.terraform_remote_state.infra.alb_hostname}"]
}
