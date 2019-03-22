#!/usr/bin/env bash

#Create production namespace
kubectl create ns production

#Create production deployments and services
kubectl --namespace=production apply -f ../k8s/production
kubectl --namespace=production apply -f ../k8s/canary
kubectl --namespace=production apply -f ../k8s/services

#Scale frontend replicas
kubectl --namespace=production scale deployment gceme-frontend-production --replicas=4

#Store External IP
export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=production services gceme-frontend)

while true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done
