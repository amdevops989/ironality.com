#!/bin/bash
/etc/eks/bootstrap.sh ${cluster_name} \
  --apiserver-endpoint ${endpoint} \
  --b64-cluster-ca ${ca_data} \
  --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=${cluster_name}-managed-nodes'
