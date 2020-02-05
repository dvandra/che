#!/usr/bin/env bash
# Copyright (c) 2020 Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
set -e
echo "========Starting nigtly test job $(date)========"
pwd
bash tests/.infra/centos-ci/nightly/nightly-happypath-test.sh


:'
echo "========Starting nigtly test job $(date)========"

source tests/.infra/centos-ci/functional_tests_utils.sh

function prepareCustomResourceFile() {
  echo "Patch custom-resource.yaml"
  cd /tmp
  wget https://raw.githubusercontent.com/eclipse/che-operator/master/deploy/crds/org_v1_che_cr.yaml -O custom-resource.yaml
  sed -i "s@openShiftoAuth: false@openShiftoAuth: true@g" /tmp/custom-resource.yaml
  sed -i "s@server:@server:\n    customCheProperties:\n      CHE_LIMITS_USER_WORKSPACES_RUN_COUNT: '-1'@g" /tmp/custom-resource.yaml
  sed -i "s/customCheProperties:/customCheProperties:\n      CHE_WORKSPACE_AGENT_DEV_INACTIVE__STOP__TIMEOUT__MS: '300000'/" /tmp/custom-resource.yaml
  sed -i "s@identityProviderImage: 'quay.io/eclipse/che-keycloak:nightly'@identityProviderImage: 'quay.io/eclipse/che-keycloak:$RELEASE_TAG'@g" /tmp/custom-resource.yaml
  sed -i "s@cheImage: ''@cheImage: 'quay.io/eclipse/che-server'@g" /tmp/custom-resource.yaml
  sed -i "s@cheImageTag: 'nightly'@cheImageTag: '$RELEASE_TAG'@g" /tmp/custom-resource.yaml
  sed -i "s@devfileRegistryImage: 'quay.io/eclipse/che-devfile-registry:nightly'@devfileRegistryImage: 'quay.io/eclipse/che-devfile-registry:$RELEASE_VERSION'@g" /tmp/custom-resource.yaml
  sed -i "s@pluginRegistryImage: 'quay.io/eclipse/che-plugin-registry:nightly'@pluginRegistryImage: 'quay.io/eclipse/che-plugin-registry:$RELEASE_VERSION'@g " /tmp/custom-resource.yaml
  cat /tmp/custom-resource.yaml
}

setupEnvs
installKVM
installDependencies
setupReleaseVersionAndTag
installAndStartMinishift
loginToOpenshiftAndSetDevRole
prepareCustomResourceFile
installCheCtl

deployCheIntoCluster  --chenamespace=eclipse-che --che-operator-cr-yaml=/tmp/custom-resource.yaml

createTestUserAndObtainUserToken
createTestWorkspaceAndRunTest 
archiveArtifacts "rc-integration-tests"
'