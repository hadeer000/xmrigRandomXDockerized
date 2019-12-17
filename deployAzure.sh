#!/bin/bash

nicehash_btc="$1"
instances=6
resourceGroup="docker-nh"
location="westeurope"

command -v jq >/dev/null 2>&1 || { echo >&2 "Install jq with apt install jq or brew install jq."; exit 1; }
originalRandomnessEntry=`jq -r '.resources[0] ' azuredeploy.json`
toBeRemovedDefaultValue=$(jq -r '.resources[0].name' azuredeploy.json )
toBeRemovedDefaultValueSanitzed=$(echo $toBeRemovedDefaultValue | tr -d '[:space:]' | sed 's/[^^]/[&]/g; s/\^/\\^/g')

generatedJson=$(cat azuredeploy.json)

for ((i=1; i<instances; i++)); do
  currentNumber=$(echo ${toBeRemovedDefaultValue} | sed "s/))/),\'-${i}\')/g")
  randInstance=$(echo $originalRandomnessEntry | sed "s/$toBeRemovedDefaultValueSanitzed/$currentNumber/g" | tr -d '\n' ) 

   if [ -n "$nicehash_btc" ] 
   then
      randInstance=$(echo $randInstance | sed "s/parameters('NicehashBTC')/\'$nicehash_btc\'/g"  )
   fi

  generatedJson=$(echo $generatedJson | jq ".resources += [$randInstance]")
done

echo $generatedJson | jq . > azuredeployEdited.json

az group create -n $resourceGroup -l $location

az group deployment create --template-file azuredeployEdited.json --parameters siteName=$resourceGroup siteLocation=$location repoUrl=none branch=master -g $resourceGroup

rm azuredeployEdited.json