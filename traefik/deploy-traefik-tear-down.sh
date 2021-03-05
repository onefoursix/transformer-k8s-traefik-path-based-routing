#!/bin/sh

# Copyright 2019 StreamSets Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# deploy-traefik-tear-down.sh

# shellcheck disable=SC2112
function usage() {
  echo "
    Usage: $0 <KUBE_NAMESPACE>

    Example: $0 namespace
  "
  # shellcheck disable=SC2242
  exit -1
}

if [ "$#" -ne 1 ]; then
    usage
fi

# Set your namespace
export KUBE_NAMESPACE=$1

## Set Context
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}

# Cleanup
kubectl delete deployment traefik-ingress-controller
kubectl delete service traefik-ingress-service
kubectl delete clusterrole traefik-ingress-controller
kubectl delete clusterrolebinding traefik-ingress-controller
kubectl delete serviceaccount traefik-ingress-controller
kubectl delete configmap traefik-conf
kubectl delete secret traefik-cert
rm -rf tls.key
rm -rf tls.crt
