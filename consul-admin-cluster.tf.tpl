
resource "kubernetes_manifest" "admin_cluster_1" {
  provider = kubernetes.eks_admin_cluster

  manifest = yamldecode(file("manifests/consul-namespace.yaml"))

  wait {
    fields = {
      "status.phase" = "Active"
    }
  }

  depends_on = [
    module.eks_admin_cluster.cluster_endpoint
  ]
}

resource "kubernetes_manifest" "admin_cluster_2" {
  provider = kubernetes.eks_admin_cluster

  for_each = fileset(path.module, "manifests/consul-crds-v0.5.3/*.yaml")
  manifest = yamldecode(file(each.value))

  depends_on = [
    kubernetes_manifest.admin_cluster_1
  ]
}

resource "kubernetes_manifest" "admin_cluster_3" {
  provider = kubernetes.eks_admin_cluster

  for_each = fileset(path.module, "manifests//consul-{bootstrap-token,license}.yaml")

  manifest = yamldecode(file(each.value))

  depends_on = [
    kubernetes_manifest.admin_cluster_2
  ]
}

resource "helm_release" "consul_admin_cluster" {
  provider = helm.eks_admin_cluster

  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  # version    = "1.0.6"
  version = "1.1.1"

  namespace = "consul"

  values = [
    # file("./manifests//consul-admin-cluster-values-v1.0.6.yaml")
    file("./manifests/consul-admin-cluster-values-v1.1.1.yaml")
  ]

  depends_on = [
    kubernetes_manifest.admin_cluster_3
  ]
}
