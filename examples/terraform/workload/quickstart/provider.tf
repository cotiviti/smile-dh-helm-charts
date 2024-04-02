provider "aws" {
  region = local.region
}

provider "helm" {

  kubernetes {
    host                   = module.smile_cdr_dependencies.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(module.smile_cdr_dependencies.eks_cluster.certificate)
    token                  = module.smile_cdr_dependencies.eks_cluster.auth_token
  }
}

provider "kubernetes" {
  host                   = module.smile_cdr_dependencies.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(module.smile_cdr_dependencies.eks_cluster.certificate)
  token                  = module.smile_cdr_dependencies.eks_cluster.auth_token
}