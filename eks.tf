data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "template" {
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name                 = "${var.name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.0.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}_cluster-1_${var.region}_${var.environment}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}_cluster-1_${var.region}_${var.environment}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.name}_cluster-1_${var.region}_${var.environment}"
  cluster_version = "1.19"
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = var.environment
  }

  workers_additional_policies = [
    aws_iam_policy.alb_ingress_controller_iam_policy.arn,
    aws_iam_policy.external_dns_iam_policy.arn
  ]

  vpc_id = module.vpc.vpc_id

  node_groups = {
    mng = {
      desired_capacity = 2
      max_capacity     = 10
      min_capacity     = 2
      instance_type = "m5a.medium"
      launch_template_id      = aws_launch_template.default.id
      launch_template_version = aws_launch_template.default.default_version
      k8s_labels = {
        Environment = var.environment
      }
      additional_tags = {
        Name = "${var.name}_mng"
      }
    }
  }
  
  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}

resource "aws_iam_policy" "alb_ingress_controller_iam_policy" {
  name   = "ALBIngressControllerIAMPolicy"
  policy = file("iam/policies/ALBIngressControllerIAMPolicy.json")
}
resource "aws_iam_policy" "external_dns_iam_policy" {
  name   = "ExternalDNSPolicy"
  policy = file("iam/policies/ExternalDNSPolicy.json")
}
