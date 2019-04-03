#!/usr/bin/env bash

DIRECTORY=$(cd `dirname $0` && pwd)

echo "install jenkins"
if [[ $(helm ls --deployed | grep cd) ]]; then
  echo "${release} already Deployed"
  helm ls --deployed
else
  helm install -n cd stable/jenkins -f ${DIRECTORY}/jenkins/values.yaml --version 0.16.6 --wait
fi

status=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].status.phase}")
i="0"
while [ ${status} != "Running" ];
do
  status=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].status.phase}")
  echo "Status: ${status}"
  if [ $i -lt 31 ]; then
    i=$[$i+1]
    echo $i
  else
    break
  fi
  sleep 10
done

if [[ ${status} == "Running" ]]; then
  export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
  kubectl get svc
  echo "Login as Admin with : $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)"
  echo "Jenkins is running at http://localhost:8081 (only accessible from within the container)
  kubectl port-forward $POD_NAME 8081:8080 >/dev/null &
else
  echo "Status: ${status}"
  echo "No Pod available, Not setting port-forwarding"
fi
echo "kubectl doesnt support 0.0.0.0 yet so http://localhost:8081 only works within container"
echo "Enable port-forward for nic 0.0.0.0 using socat for routing fix...  "
echo "Access Jenkins at http://localhost:8080 "
socat tcp-listen:8080,fork tcp:127.0.0.1:8081 &
