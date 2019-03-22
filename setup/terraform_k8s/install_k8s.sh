#!/usr/bin/env bash

##############################################################################################
# Description	: Configure your GCP environment variables in the Global Variables section below
#               and this script will use terraform to build k8s
#
# PreReqs      : Setup GCP Account, Create storage bucket, enable API
#               Create IAM service account (download JSON credentials)
#                 Add Roles : Project Editor, K8s Admin, Cloud Build Service Account,
#                             Storage Object Creator, Cloud repo
# Author       :Patrick Presto
# Email        :pgprestok@gmail.com
#
# Usage        :   ./setup_k8s_helm_jenkins.sh
#
##############################################################################################

#Global Variables
export TF_VAR_project="cicd-234921"
export TF_VAR_region="us-west1"
export TF_VAR_bucket="${TF_VAR_project}"
export TF_VAR_prefix="/terraform/cicd"
export TF_VAR_credentials="../secrets/${TF_VAR_project}.json"

terraform init \
  -backend-config "bucket=${TF_VAR_bucket}" \
  -backend-config "prefix=${TF_VAR_prefix}" \
  -backend-config "credentials=${TF_VAR_credentials}"

terraform plan \
-var "project=${TF_VAR_project}" \
-var "cluster_name=${TF_VAR_project}-cluster-1" \
-var "cluster_region=${TF_VAR_region}"

echo "sleeping 5 sec"
sleep 5

terraform apply -auto-approve \
  -var "project=${TF_VAR_project}" \
  -var "cluster_name=${TF_VAR_project}-cluster-1" \
  -var "cluster_region=${TF_VAR_region}"
