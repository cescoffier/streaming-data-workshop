#!/bin/bash

set -e
set -x

WORKSHOP=streaming-data-workshop
WORKSHOP_DIR=${HOME}/${WORKSHOP}

git clone https://github.com/infinispan-demos/${WORKSHOP} ${WORKSHOP_DIR}

cd ${WORKSHOP_DIR}
./start-openshift.sh
./start-datagrid.sh
mvn install fabric8:deploy dependency:go-offline

cd ${WORKSHOP_DIR}/datagrid-visualizer
./deploy.sh

cd ${WORKSHOP_DIR}/web-viewer
nvm use 4.2
npm install
npm run build

# Expecting 7 app pods plus 3 ISPN pods
EXPECTED_PODS=10
START=$(date -u +%s)
until [ "$(oc get pods -a=false -o=name | wc -l)" -eq "${EXPECTED_PODS}" ]; do
    printf '.'
    sleep 5
    if [ "$(bc <<< "$(date -u +%s)-${START}")" -gt "15" ]; then
        # Timeout
        exit 128
    fi
done

oc cluster down
