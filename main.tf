provider "aws" {
  region     = "ap-south-1"
}


terraform {
  backend "s3" {
    bucket = "yogi-tf"
    key    = "terraform-backend/eks-nodegroup.tf"
    region = "ap-south-1"
  }
}



locals {
  name   = "Sandbox-Cluster-Test"
  region = "ap-south-1"

 
  azs      = slice(data.aws_availability_zones.yogi-az.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}



data "aws_vpc" "yogi-vpc"{

filter {
 name = "tag:Name"
 values = ["Yogi-VPC-DevOps"]
}
}

data "aws_iam_role" "example" {
  name = "sandboxcluster-eks-iam-role"
}


data "aws_availability_zones" "yogi-az" {
  state = "available"
}

resource "aws_subnet" "public-subnets" {
  count = 3

  vpc_id            = data.aws_vpc.yogi-vpc.id
  cidr_block = var.public-subnet-cidr1[count.index]
 

  tags = {
    Name = "Public-k8s-subnet"
  }
    availability_zone = "${data.aws_availability_zones.yogi-az.names[count.index]}"
  map_public_ip_on_launch = true
}

data "aws_route_table" "publicrt" {
   vpc_id            = data.aws_vpc.yogi-vpc.id
  filter {
   name = "tag:Name"
   values = ["public-route-table"]
  }
}


resource "aws_route_table_association" "public-route-1" {
  count = "${length(var.public-subnet-cidr1)}"
  //subnet_id      = "${data.aws_subnet_ids.public-subnets.ids}"
  //subnet_id =   "${element(data.aws_subnet.public-subnets.*.id, count.index)}" 
  subnet_id = "${element(aws_subnet.public-subnets.*.id, count.index)}"
  route_table_id = data.aws_route_table.publicrt.id
}


module "eks_nodegroup_role" {
source = "./eks-role"
}


module "eks_cluster_creation" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.13.1"
  cluster_name                   = local.name
  //iam_role_arn = data.aws_iam_role.example.arn
  iam_role_arn = module.eks_nodegroup_role.eks_role
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = false
  subnet_ids        =  flatten([aws_subnet.public-subnets[*].id])
  vpc_id    = data.aws_vpc.yogi-vpc.id
  //create_kms_key = false
  depends_on = [module.eks_nodegroup_role]
}

//module "nodegroup_creation" {
//source = "./node-group-creation"
//depends_on = [module.eks_cluster_creation]
//}

