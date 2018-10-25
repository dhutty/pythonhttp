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

variable "image_tag"{
  default = "latest"
}

output "target_url" {
  value ="pythonhttp.${var.namespace}.${var.zone}"
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

module "ecs-web-service"{
  source             = "git::https://gitlab.com/dhutty/modern-provisioning_code.git//tf/modules/ecs-web-service?ref=modules"
  name               = "pythonhttp"
  namespace          = "${var.namespace}"
  add_to_dns         = true
  zone               = "${var.zone}"
  alb_hostname       = "${data.terraform_remote_state.infra.alb_hostname}"
  alb_listener_arn   = "${data.terraform_remote_state.infra.alb_listener_arn}"
  vpc_id             = "${data.terraform_remote_state.infra.vpc_id}"
  execution_role_arn = "${data.terraform_remote_state.infra.execution_role_arn}"
  public_subnet_ids  = "${data.terraform_remote_state.infra.public_subnet_ids}"
  security_group_ids = "${data.terraform_remote_state.infra.security_group_ids}"
  aws_region         = "${var.aws_region}"
  ecs_cluster_id     = "${data.terraform_remote_state.infra.ecs_cluster_id}"
  container = {
    name    = "pythonhttp"
    image   = "registry.gitlab.com/dhutty/pythonhttp:${var.image_tag}"
    cpu     = 256
    memory  = 512
    port    = 8080
    }
}
