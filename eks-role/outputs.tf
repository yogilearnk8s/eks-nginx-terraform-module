output "eks_role" {
  description = "Role arn for eks cluster"
  value       = "${aws_iam_role.eks-iam-role.arn}"  
  
}



//output "workernodes_role" {
//  description = "Role arn for worker nodes"
//  value       = module.aws_iam_role.workernodes.arn
//}

