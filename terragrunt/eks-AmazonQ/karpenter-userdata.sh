#!/bin/bash

set -o xtrace

/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${certificate_authority} \
  --apiserver-endpoint ${endpoint} \
  --container-runtime containerd \
  --kubelet-extra-args '--node-labels=karpenter.sh/provisioner-name=${cluster_name}-spot-nodeclass'
