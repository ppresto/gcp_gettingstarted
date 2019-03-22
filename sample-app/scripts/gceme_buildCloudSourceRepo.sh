#!/usr/bin/env bash

gcloud source repos create gceme

# Initialize sample-app repo
cd ../
git init
git config credential.helper gcloud.sh
export PROJECT_ID=$(gcloud config get-value project)
git remote add origin https://source.developers.google.com/p/$PROJECT_ID/r/gceme
git config --global user.email "pgpresto@gmail.com"
git config --global user.name "ppresto"
git add .
git commit -m "Initial commit"
git push origin master
