# Need a Free K8s Env for personal development?
By using the initial $300 GCP offers + terraform to build/destroy GKE daily along with a couple simple scripts (install helm and jenkins) I can have my GKE Env ready for me with 1 command in 10 minutes and run it for over 1 year.  This is a tutorial covering the steps I've taken to build my development GKE clustert and includes a CI/CD example Jenkinsfile and app that can deploy to a canary then full env for any branch.

## Highlights
* Run local container to manage your GCP Project (auth only first time not subsequent runs)
* Create/Destroy your GKE cluster using Terraform storing tfstate in Google Storage.
* Install Helm
* Install stable/jenkins using Helm
* Configure Jenkins Job for CI/CD using GKE
* Promote and Deploy new code to Canary target and then Prod.

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Need a Free K8s Env for personal development?](#need-a-free-k8s-env-for-personal-development)
	- [Highlights](#highlights)
- [Create New Project](#create-new-project)
	- [Name](#name)
	- [Billing](#billing)
	- [API's](#apis)
	- [Cloud Shell](#cloud-shell)
	- [Create IAM Service Account in your Project](#create-iam-service-account-in-your-project)
	- [Create Storage Bucket](#create-storage-bucket)
	- [Access your GCP project in Cloud Shell and set your zone](#access-your-gcp-project-in-cloud-shell-and-set-your-zone)
- [Setup and Use gcloud containers (Optional)](#setup-and-use-gcloud-containers-optional)
	- [Pull Image from Dockerhub](#pull-image-from-dockerhub)
	- [Authentication](#authentication)
		- [Create initial conatiner](#create-initial-conatiner)
- [Build Kubernetes](#build-kubernetes)
	- [Clone the repo](#clone-the-repo)
	- [Edit install_k8s.sh](#edit-installk8ssh)
- [Global Variables](#global-variables)
	- [Build](#build)
- [Deploy GCP sample-app to your cluster](#deploy-gcp-sample-app-to-your-cluster)
	- [Initial Deployment](#initial-deployment)
	- [Create Cloud Source Repo](#create-cloud-source-repo)
	- [Setup Jenkins](#setup-jenkins)
	- [Deploy changes](#deploy-changes)
- [K8s Admin Cheatsheet](#k8s-admin-cheatsheet)
	- [Helm](#helm)
	- [Pods](#pods)
	- [Networking](#networking)
	- [Resources](#resources)
- [References](#references)

<!-- /TOC -->

Lets get Started...

# Create New Project
## Name
In my GCP instance I'm creating project: cicd-234921.  I've appended my Project ID # "234921" to make it clear in the future.
## Billing
Make sure billing is enabled
## API's
API's are critical for integration and automation.
* Enable API's: https://console.cloud.google.com/flows/enableapi?apiid=compute_component,container,cloudbuild.googleapis.com&_ga=2.98511455.-1944407796.1552514124&_gac=1.60353887.1552514124.CjwKCAjw1KLkBRBZEiwARzyE77U2YB9wZoiRy9JdOUxBY4zUUSP42PgjlpwUilV2tC0DMBojTPzSoxoCYBkQAvD_BwE

## Cloud Shell
Cloud Shell is a terminal available through your browser when you click on a "connect" button.  This lets you do any administration needed in your GCP environment.  I found this feature very useful, and next to it are options to manage files, and view proxied content from your GCP env.  There are alternatives to Cloud Shell like gcloud discussed later on.
* Activate Cloud Shell: https://console.cloud.google.com/?cloudshell=true&_ga=2.69545424.-1944407796.1552514124&_gac=1.263463678.1552514124.CjwKCAjw1KLkBRBZEiwARzyE77U2YB9wZoiRy9JdOUxBY4zUUSP42PgjlpwUilV2tC0DMBojTPzSoxoCYBkQAvD_BwE

## Create IAM Service Account in your Project
I created a service account matching my project name for simplicity.  Be sure to add all the roles you need and once your account is built you will need to create a key.  be sure to save this key somewhere you wont lose it and be careful not to commit it to github!
* Add Roles
  - Project Editor
  - K8s Admin
  - Cloud Build Service Account
  - Storage Object Creator
  - Cloud repo
* Create Key and copy to ./secrets/${PROJECT}.json

## Create Storage Bucket
We will use this bucket to save our terraform state.  It supports DR and file locking so any # of users can use this solution without impacting the integrity of the state.  I named my bucket using ${PROJECT}, and configured addition sub directories or prefix /terraform/cicd.
* Create Storage Bucket.  Ex: cicd-234921
* Create directories to organize content.  Ex: terraform/cicd

## Access your GCP project in Cloud Shell and set your zone
* At the top of you GCP Dashboard make sure you see your project selected.  If you have multiple then click on projects (3rd option from the left).
* You should see a powershell type icon on  the top left side of the header.  Click on this to activate cloud shell.
* The cloud shell has very helpful messages and often gives you exact commands to cut/paste like how to initially set your project.  Lets set our project, list available zones, and set the one that makes sense for us.
  - gcloud config set project ${PROJECT}
  - gcloud compute zones list
  - gcloud config set compute/zone us-west1-a

# Setup and Use gcloud containers
An alternative to using the cloud shell would be to use the gcloud docker image.  If you already have docker installed and are familiar with containers this may be a convenient option for you.  I found this to be very useful, with the only limitation being that kubectl sets proxies to use 127.0.0.1 with no option to bind to 0.0.0.0.  So if you want to proxy one of your GCP apps to your workstation you will need to use something like socat in your container.  If you want something working easy and fast I found  cloud shell to work great.  I've decided to use a local container for this tutorial.

## Pull Image from Dockerhub
* Setup a dockerhub account if you dont already have one.
`docker pull google/cloud-sdk`

## Create Custom GCP cloud-sdk docker image
I have created a custom image from google/cloud-sdk to add a few tools I need including terraform, socat, and unzip.  This allows me to kick everything off from a single terminal session easily and quick.  If you want to walk through this tutorial easily, execute terraform, and have quick access to your jenkins server locally I recommend using this image or something similar.  You can easily use the GCP Cloud Shell from your browser as long as you have terraform installed somewhere for the next section.
FYI:  socat is required for the container to proxy kubectl services like the jenkins server we will install later.

```
cd ./mygcloud
docker build -t <DOCKERHUB_ID>/mygcloud .
docker images
```

example output:
`ppresto/mygcloud                          latest              cf15fbd3b72e        13 days ago         1.88GB`

## Authentication
Everytime you run a container from this image you will need to authenticate with GCP.  GCP will store your authenticated credentials in the root volume of the container.  This is am extra step and its something we can easily fix with the --volumes-from docker option.  In summary,  we are going to start a container for ${PROJECT}, authenticate, and then kill it.  The container will still be available so we will use its root volume when we start other containers allowing us to skp this step everytime.

### Create initial conatiner
1. Run the intial container using a name that makes sense for your environment (ex: gcloud-cicd).
2. For admin/development tasks I mount a volume from my workstation (~/myProjects)
3. During gcloud init step you will need to cut/paste the text in your browser and login to Google with the same account your project is under.  You will also be given a list of regions and asked to select the one that is best for you.  These will be 1 time tasks.
```
docker run -it --name gcloud-cicd -v $HOME/Projects:/Projects/ ppresto/mygcloud bash
gcloud init

Select: [1] Re-initialize this configuration [default] with new settings

You must log in to continue. Would you like to log in (Y/n)?  Y

Enter verification code:

Select Project: 1

Do you want to configure a default Compute Region and Zone? (Y/n)?  Y

```
2. If you want your future containers to use your credentials then you are done.  If you want them to use your service account instead then you will need to authenticate with it using the name and ${PROJECT}.json.  For example,
```
gcloud auth activate-service-account cicd-234921@cicd-234921.iam.gserviceaccount.com --key-file=/Projects/DevOps/gcp_gettingstarted/setup/secrets/cicd-234921.json
```
3. Exit your container to stop it.  Kill but don't rm this container!
`exit`

### Run new containers that use this initial container
4. Start your new container using any options you want and including the root volumes from the one we just stopped.  I use the --rm flag to keep things clean after I stop this tmp container.  Once you have it running try using gcloud to confirm you are connected to your account.
```
docker run --rm -ti -p 8080:8080 --volumes-from gcloud-cicd ppresto/mygcloud bash
gcloud container operations list

```
We haven't built anything yet so we can move on to the next section now.  However, if you are running a new container to manage and existing cluster remember, although you are authenticated you still need to get the credentials of any existing cluster you want to manage. For example,
`gcloud container clusters get-credentials cicd-234921-cluster-1 --zone us-west1-a --project cicd-234921`

# Build Kubernetes
## Clone the repo
```
cd /projects
git clone https://github.com/ppresto/gcp_gettingstarted.git
cd gcp_gettingstarted/setup/terraform_k8s
```
## Edit install_k8s.sh
Edit the Global Variables with your GCP project, region, storage, and credentials and save.
```
#Global Variables
export TF_VAR_project="cicd-234921"
export TF_VAR_region="us-west1"
export TF_VAR_bucket="${TF_VAR_project}"
export TF_VAR_prefix="/terraform/cicd"
export TF_VAR_credentials="../secrets/${TF_VAR_project}.json"
```
Note:  Storing terraform state happens before terraform can load variables.  To make this setup more configurable for others and remove hard coding from the terraform templates I added an extra resource in remote_state.tf, and passed variables on the command line.  This can easily be modified so you can just run "terraform apply", but as is I recommend you use the install, destroy scripts here that have the proper variables being passed at run time.

## Build
Run the install_k8s.sh.
```
./install_k8s.sh
```
Stages:
1. terraform init will download dependencies and setup your state file.
2. terraform plan will execute to show you what will be built.  You have 5 secs to Ctrl+c
3. terraform apply will build your k8s cluster with a default pool
4. terraform show will show you whats built.

# Deploy GCP sample-app to your cluster
## Initial Deployment
```
cd ./gcp_gettingstarted/sample-app
```
1. Create production namespace to logically separate it
`kubectl create ns production`
2. Create deployments and services
```
kubectl --namespace=production apply -f k8s/production
kubectl --namespace=production apply -f k8s/canary
kubectl --namespace=production apply -f k8s/services
```
3. Scale up front-ends
`kubectl --namespace=production scale deployment gceme-frontend-production --replicas=4`
4. Get external IP (can take a long time), and store in variable
```
kubectl --namespace=production get service gceme-frontend
export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=production services gceme-frontend)
```
5. Open new window and poll endpoint /version to see rolling updates after deployment to canary
`while true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done`

## Create Cloud Source Repo
1. Be sure you are inside the sample-app directory ./sample-app
2. create repo
`gcloud source repos create gceme`
3. configure git and push initial commit
```
git init
git config credential.helper gcloud.sh
export PROJECT_ID=$(gcloud config get-value project)
git remote add origin https://source.developers.google.com/p/$PROJECT_ID/r/gceme
git config --global user.email "pgpresto@gmail.com"
git config --global user.name "Patrick Presto"
git add .
git commit -m "Initial commit"
git push origin master
```

## Setup Jenkins
1. Add Global Credentials of type: Google Service Account from metadata
2. Create multipipeline job named “sample-app"
    1. Add Source: Git
        1. repo: https://source.developers.google.com/p/${PROJECT_ID}/r/gceme
        2. enable the service account credentials we just created
    2. Scan Multibranch pipeline Triggers:  Check Periodically if not otherwise ran, set 1 min interval.
    3. Keep old items 1 day to have build log history for easy troubleshooting
    4. save
    5. Pipeline runs, discovers master branch.  If this fails review Jenkinsfile details for proper project and repo locations.

## Deploy changes
3. Update repo with canary branch and create version 2.
`git checkout -b canary`
    2. vi Jenkinsfile and update project value
    3. vi html.go and update 2 cases of blue with orange
    4. vi main.go and change version to 2.0.0
```
git add .
git commit -m “version 2"
git push origin canary
```
4. Get Status
    1. Review Jenkins pipeline and console output
    2. Look at the polling /version window and see the canary deployment
5. Push to Master
Review status, pods, replicas, deployment, and app functionality before final push to master.
```
git checkout master
git merge canary
git push origin master
```
6. Poll production URL
```
export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}" --namespace=production services gceme-frontend)

while true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done
```

# My K8s Admin Cheatsheet
## Helm
* helm ls --all
* helm repo list
* helm search
* helm [status|history|delete|rollback] <RELEASE>
* helm del --purge <RELEASE>
## Pods
Get logs, events, and other information
```
kubectl logs <POD_NAME>
kubectl logs <POD_NAME> -c <CONTAINER_NAME>
kubectl describe pod <POD_NAME>
kubectl get events
kubectl get endpoints
kubectl get pods --all-namespaces -o yaml
kubectl get pods --all-namespaces --show-labels
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}’ | sort
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.name}{", "}{end}{end}' | sort
```
Run commands in Pods.  Start of pod name is usualy container name.
```
kubectl run -it --rm --restart=Never busybox --image=busybox sh
kubectl exec sa-frontend-5769ff78c4-sgfvz -c sa-frontend -- bash
```

## Networking
* Use curl
`kubectl run client --image=appropriate/curl --rm -ti --restart=Never --command -- curl http://my-service:80`
* Use nslookup
`kubectl run busybox --image=busybox --rm -ti --restart=Never --command -- nslookup my-service`
* Forward Container port to localhost
`kubectl port-forward <POD_NAME> <POD_PORT>`
* Check K8s API
```
kubectl run curl --image=appropriate/curl --rm -ti --restart=Never --command -- sh -c 'KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) && curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT/api/v1/namespaces/default/pods'
```

## Resources
* Resize node pool by getting cluster name, node-pool name and running resize
```
gcloud container clusters list
glcoud container node-pools list --cluster CLUSTER_NAME
gcloud container clusters resize CLUSTER_NAME --node-pool NODE_POOL --size 4
```

# References
* https://cloud.google.com/solutions/jenkins-on-kubernetes-engine
* https://youtu.be/IDoRWieTcMc
* https://cloud.google.com/solutions/jenkins-on-kubernetes-engine-tutorial
* https://cloud.google.com/solutions/continuous-delivery-jenkins-kubernetes-engine
