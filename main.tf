provider "aws" {
  region     = "ap-south-1"
}

//data "aws_eks_cluster" "default" {
//  name = module.eks_cluster_creation.cluster_id
//}

//data "aws_eks_cluster_auth" "default" {
//  name = module.eks_cluster_creation.cluster_name
//}

//provider "kubernetes" {
//  host                   = module.eks_cluster_creation.cluster_endpoint
//  cluster_ca_certificate = base64decode(module.eks_cluster_creation.cluster_certificate_authority_data)
//  token = data.aws_eks_cluster_auth.default.token
//}

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

//data "aws_iam_role" "example" {
//  name = "sandboxcluster-eks-iam-role"
//}


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
  
  //  manage_aws_auth_configmap = true
    aws_auth_users = [
    {
      userarn  = "arn:aws:iam::014742839986:user/yogitest"
      username = "yogitest"
      groups   = ["system:masters"]
    }
  ]
  
    aws_auth_accounts = [
    "014742839986"
  ]
  
  depends_on = [module.eks_nodegroup_role]
}

resource "kubernetes_config_map" "example" {
  metadata {
    name = "example-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers: |
      - userarn: arn:aws:iam::014742839986:user/yogitest
        username: yogitest
        groups:
        - system:masters
  }

  depends_on = [module.eks_cluster_creation.cluster_name]
}


//module "nodegroup_creation" {
//source = "./node-group-creation"
//depends_on = [module.eks_cluster_creation]
//}

