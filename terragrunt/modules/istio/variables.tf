variable "k8s_host" {
  type = string
}
variable "k8s_ca" {
  
}

variable "cluster_name" {
  
}

variable "region" {
  
}

variable "profile" {
  
}

variable "domain_filters" {
  
}

# kubectl patch svc gateway -n istio-ingress \
#   -p '{"metadata": {"annotations": {"external-dns.alpha.kubernetes.io/hostname": "travelersources.com,api.travelersources.com,frontend.travelersources.com"}}}'

# kubectl patch svc gateway -n istio-ingress \
#   -p '{"metadata": {"annotations": {"external-dns.alpha.kubernetes.io/hostname": "travelersources.com,api.travelersources.com,frontend.travelersources.com,test.travelersources.com"}}}'
