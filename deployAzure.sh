#!/bin/bash

instances=2
resourceGroup="docker-nh"
location="westeurope"

command -v jq >/dev/null 2>&1 || { echo >&2 "Install jq with apt install jq or brew install jq."; exit 1; }
originalRandomnessEntry=`jq -r '.resources[0] ' azuredeploy.json`
toBeRemovedDefaultValue=$(jq -r '.resources[0].name ' azuredeploy.json | tr -d '[:space:]' | sed 's/[^^]/[&]/g; s/\^/\\^/g')

generatedJson=$(cat azuredeploy.json)


for ((i=1; i<=instances; i++)); do
  currentNumber=$(echo ${resourceGroup}-${i})
  randInstance=$(echo $originalRandomnessEntry | sed "s/$toBeRemovedDefaultValue/$currentNumber/g" | tr -d '\n' ) 
  generatedJson=$(echo $generatedJson | jq ".resources += [$randInstance]")
done

echo $generatedJson | jq .

#az group create -n $resourceGroup -l $location

#az group deployment create --template-file azuredeploy.json --parameters siteName=$resourceGroup siteLocation=$location repoUrl=none branch=master -g $resourceGroup
