data "aws_vpc" "yogi-vpc"{

filter {
 name = "tag:Name"
 values = ["Yogi-VPC-DevOps"]
}
}


//data "aws_subnet" "public-subnets" {
//  count = "${length(var.public-subnet-cidr)}"
// vpc_id = data.aws_vpc.yogi-vpc.id
//
//  filter {
//    name   = "tag:Name"
//    values = ["public-subnet-*"] 
//  }
//}

data aws_subnets "public-subnets" {
 //vpc_id = data.aws_vpc.yogi-vpc.id

  //filter {
  //  name   = "tag:Name"
  //  values = ["Public-k8s-*"] 
  //}
  filter {
   name   = "vpc-id"
   values = [data.aws_vpc.yogi-vpc.id]
  }
  tags = {
   Name = "Public-k8s-subnet"
  }
}

data "aws_iam_role" "example" {
  name = "eks-node-group-example"
}

data "aws_eks_cluster" "eks_creation" {
  name = var.eks-cluster-name1 
}

data "aws_subnet" "public-subnets" {
//count = "${length(data.aws_subnet_ids.public-subnets.ids)}"
count = "${length(var.public-subnet-cidr)}"
id = "${tolist(data.aws_subnets.public-subnets.ids)[count.index]}"
}

resource "aws_eks_node_group" "worker-node-group" {
 count = "${length(var.public-subnet-cidr)}"
  cluster_name  = data.aws_eks_cluster.eks_creation.name
  node_group_name = "sandbox-workernodes"
  node_role_arn  = data.aws_iam_role.example.arn
  //subnet_ids = "${toset(element(data.aws_subnet.public-subnets.*.id, count.index))}"
  //subnet_ids =  data.aws_subnet.public-subnets[*].id
  subnet_ids = flatten([data.aws_subnet.public-subnets[*].id])
  //subnet_ids = ["subnet-06fa0847fb0ac8845","subnet-0ae53cf68d4b875f4"]
  instance_types = ["t2.medium"]
 
  scaling_config {
   desired_size = 2
   max_size   = 2
   min_size   = 1
  }
 
//  depends_on = [
  // aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   //aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  //]
 }

  
 