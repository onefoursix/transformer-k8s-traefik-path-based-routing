#!/bin/sh


## Set these variables
SCH_URL=https://cloud.streamsets.com
SCH_ORG=
SCH_USER=user@org
SCH_PASSWORD=
KUBE_NAMESPACE=
CLUSTER_TYPE=
TRANSFORMER_EXTERNAL_URL=https://<hostname>/transformer/



## Get auth token fron Control Hub
echo "Getting SCH Token..."
export SCH_TOKEN=$(curl -s -X POST -d "{\"userName\":\"${SCH_USER}\", \"password\": \"${SCH_PASSWORD}\"}" ${SCH_URL}/security/public-rest/v1/authentication/login --header "Content-Type:application/json" --header "X-Requested-By:SDC" -c - | sed -n '/SS-SSO-LOGIN/p' | perl -lane 'print $F[$#F]')
if [ -z "$SCH_TOKEN" ]; then
  >&2 echo "Failed to authenticate with SCH :("
  >&2 echo "Please check your username, password, and organization name."
  exit 1
fi

## Use the auth token to get a registration token for a Control Agent
echo "Getting transformer Token..."
TRANSFORMER_TOKEN=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG}\", \"componentType\" : \"transformer\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq '.[0].fullAuthToken' | tr -d '"')

if [ -z "$TRANSFORMER_TOKEN" ]; then
  >&2 echo "Failed to generate transformer token."
  >&2 echo "Please verify you have Auth Token Generator permission in StreamSets Control Hub"
  exit 1
fi

## Store the agent token in a secret
kubectl create secret generic streamsets-transformer-creds \
    --from-literal=transformer_token_string="${TRANSFORMER_TOKEN}"

## Generate a UUID for the transformer
transformer_id=$(docker run --rm andyneff/uuidgen uuidgen -t)
echo "${transformer_id}" > transformer.id

    
## Store connection properties in a configmap for the transformer
kubectl create configmap streamsets-transformer-config \
    --from-literal=org="${SCH_ORG}" \
    --from-literal=sch_url="${SCH_URL}" \
    --from-literal=transformer_id="${transformer_id}" \
    --from-literal=transformer_external_url="${TRANSFORMER_EXTERNAL_URL}"    

## Create a service account to run the transformer
kubectl create serviceaccount streamsets-transformer --namespace="${KUBE_NAMESPACE}"

## Create a role for the service account with permissions to
## create pods (among other things)
kubectl create role streamsets-transformer \
    --verb=get,list,watch,create,update,delete,patch \
    --resource=pods,secrets,configmaps,replicasets,ingresses,services,events \
    --namespace="${KUBE_NAMESPACE}"

## Bind the role to the service account
kubectl create rolebinding streamsets-transformer \
    --role=streamsets-transformer \
    --serviceaccount="${KUBE_NAMESPACE}":streamsets-transformer \
    --namespace="${KUBE_NAMESPACE}"



# Deploy Transformer
kubectl apply -f yaml/transformer.yaml

# Deploy Transformer Service
kubectl apply -f yaml/service.yaml




