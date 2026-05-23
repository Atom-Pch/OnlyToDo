module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 21.20.0"

  name               = "todo-eks-cluster"
  kubernetes_version = "1.35"

  vpc_id                   = var.vpc
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets

  # Core EKS Addons (Recommended in v21+)
  addons = {
    coredns = {}
    vpc-cni = {
      before_compute = true # THE MOST IMPORTANT PART!! DO NOT FORGET OR YOU WILL SPEND HOURS DEBUGGING!!
    }
    kube-proxy = {}
    eks-pod-identity-agent = {
      before_compute = true # THE MOST IMPORTANT PART!! DO NOT FORGET OR YOU WILL SPEND HOURS DEBUGGING!!
    }
  }

  # Gives you local kubectl access
  endpoint_public_access  = true
  endpoint_private_access = true # CRITICAL for NAT-less worker nodes

  # Utilizes the new Cluster Access Entry API to grant you admin rights
  enable_cluster_creator_admin_permissions = true

  # EKS Managed Node Group
  eks_managed_node_groups = {
    todo_nodes = {
      # AL2023 is the default AMI type for EKS managed node groups starting 1.30
      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # CRITICAL FIX for v21+: Give the node permissions to run VPC CNI
    #   iam_role_attach_cni_policy = true
    }
  }

  deletion_protection = false
}
