#!/bin/sh

# deploy-traefik.sh

# This script assumes cert and key exist in same directory as tls.crt and tls.key

# Set your namespace
export KUBE_NAMESPACE=ns1

# set context
kubectl config set-context $(kubectl config current-context) --namespace="${KUBE_NAMESPACE}"

# Create a service account
kubectl create serviceaccount traefik-ingress-controller --namespace=${KUBE_NAMESPACE}

# Create a cluster role
kubectl create clusterrole traefik-ingress-controller \
    --verb=get,list,watch \
    --resource=endpoints,ingresses.extensions,services,secrets
    
# Bind the service account to the role
kubectl create clusterrolebinding traefik-ingress-controller \
    --clusterrole=traefik-ingress-controller \
    --serviceaccount=${KUBE_NAMESPACE}:traefik-ingress-controller

# Store the cert in a secret  
kubectl create secret generic traefik-cert --namespace=${KUBE_NAMESPACE} \
    --from-file=tls.crt \
    --from-file=tls.key

# Load the traefik.toml file into a configmap
kubectl create configmap traefik-conf --from-file=traefik.toml --namespace=${KUBE_NAMESPACE}

# Create traefik service
kubectl create -f traefik-dep.yaml --namespace=${KUBE_NAMESPACE}

