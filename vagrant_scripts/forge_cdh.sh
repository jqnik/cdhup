#!/bin/bash

BASE=$1
CLUSTER_CONF=$2
SLEEP=80

echo "==> Sleeping $SLEEP s for CM to become available"
sleep $SLEEP

cd $BASE
python provisionator.py $CLUSTER_CONF
