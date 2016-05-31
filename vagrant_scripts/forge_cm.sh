#!/bin/bash

FORGE_BASE=$1
DB_TYPE=$2
DB_PASS=$3

cd $FORGE_BASE
source $FORGE_BASE/provision/scm/scm_quick_install.env
bash $FORGE_BASE/provision/scm/scm_quick_install.sh $DB_TYPE $DB_PASS
