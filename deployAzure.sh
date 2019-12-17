#!/bin/bash

#the rg this should be deployed into
resourceGroup="docker-nh"

wantedEurConsumption="$1"
#if no first parameter is send we will spend about one euro
if [ -z "$wantedEurConsumption" ]
then
   wantedEurConsumption=1
fi

#your nicehash btc addr
nicehash_btc="$2"

# in how many minutes the work should be done?
timeFrame=60

#-------
#end of configuration

costPerDay=2.86

set -f
instancesCalc="\"$wantedEurConsumption / ( $timeFrame * ( $costPerDay / (24 * 60)))\""
instances=$(bash -c "echo $instancesCalc | bc -l")
set +f
instances=$(echo ${instances%\.*})

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

az group create -n $resourceGroup -l westeurope

az group deployment create --template-file azuredeployEdited.json --parameters siteName=$resourceGroup -g $resourceGroup

rm azuredeployEdited.json

sleep $(($timeFrame * 60))

az group delete -n $resourceGroup -y

echo "Finished!"
