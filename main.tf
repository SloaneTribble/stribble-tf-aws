terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "stribble-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  count = 1
  name  = "my-ec2-cluster-${count.index}"

  ami                    = "ami-04e5276ebb8451442"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  tags = {
    Terraform            = "true"
    Environment          = "sandbox"
    Application          = "stribble-modules-exercise"
    Owner                = "stribble"
    Project              = "dob"
    Automation-Candidate = "true"
    Client               = "internal"
  }
}

module "website_s3_bucket" {
  source = "./modules/s3-bucket"

  bucket_name = "stribble-tf-module-bucket"
}