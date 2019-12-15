#!/bin/bash

RAND=`echo $RANDOM % 1000 + 1 | bc`

az container create -g nh-docker --name nh-$RAND --image debar/xmrig --cpu 4 --memory 2.5 --restart-policy Never --environment-variables XMRIG_USER=3LUvVmhHLLZBSaprdSZYSBFnBu7ybZg7nh.docker${RAND}
