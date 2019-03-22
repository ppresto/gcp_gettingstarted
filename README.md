# gcp_gettingstarted
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [gcp_gettingstarted](#gcpgettingstarted)
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
- [Deploy Sentiment Analyzser (3 micro services)](#deploy-sentiment-analyzser-3-micro-services)
- [K8s Administration Notes](#k8s-administration-notes)

<!-- /TOC -->

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

# Setup and Use gcloud containers (Optional)
An alternative to using the cloud shell would be to use the gcloud docker image.  If you already have docker installed and are familiar with containers this may be a more comfortable option for you.  I found this to be very useful, with the only limitation being that kubectl setups up proxies to use 127.0.0.1 with no option to bind to 0.0.0.0.  So if you want to proxy one of your GCP apps to your workstation you will need to use something like socat in your container.
## Pull Image from Dockerhub
* Setup a dockerhub account if you dont already have one.
`docker pull google/cloud-sdk`

## Authentication
Everytime you run a container from this image you will need to authenticate with GCP.  GCP will store your authenticated credentials in the root volume of the container.  This is am extra step and its something we can easily fix with the --volumes-from docker option.  In summary,  we are going to start a container for ${PROJECT}, authenticate, and then kill it.  The container will still be available so we will use its root volume when we start other containers allowing us to skp this step everytime.
### Create initial conatiner
1. Run the intial container using a name that makes sense for your environment and is easy to remember (ex: gcloud-cicd).  During gcloud init step you will need to cut/paste the text in your browser and login to Google with the same account your project is under.  You will also be given a list of regions and asked to select the one that is best for you.
```
docker run -it --name gcloud-cicd -v $HOME/myProjects:/myProjects/ google/cloud-sdk bash
gcloud init
```
2. If you want your future containers to use your credentials then you are done.  If you want them to use your service account instead then you will need to authenticate with it using the name and ${PROJECT}.json.  For example,
```
gcloud auth activate-service-account cicd-234921@cicd-234921.iam.gserviceaccount.com --key-file=$HOME/myProjects/gcp_gettingstarted/secrets/cicd-234921.json
```
3. Exit your container to stop it.
`exit`
4. Start your new container using any options you want and including the root volumes from the one we just stopped.  I use the --rm flag to keep things clean after I stop this container.  Once you have it running try using gcloud to confirm you are connected to your account.
```
docker run --rm -ti -p 8080:8080 --volumes-from gcloud-cicd google/cloud-sdk bash
gcloud container operations list
```


# Build Kubernetes
## Clone the repo
```
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

# Deploy Sentiment Analyzser (3 micro services)
# K8s Administration Notes
