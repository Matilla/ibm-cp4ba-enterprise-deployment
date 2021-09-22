#!/bin/bash

wait_for_k8s_resource_condition_generic () {
  local resourceName="${1}"
  local jqStatement="${2}"
  local testValue="${3}"
  local attempts="${4:-${DEFAULT_ATTEMPTS}}"
  local delay="${5:-${DEFAULT_DELAY}}"

  local attempt=0
  echo "Waiting on resource '${resourceName}' for jq statement '${jqStatement}' to return value '${testValue}' with '${attempts}' attempts with '${delay}' seconds delay each (total of `expr ${attempts} \* ${delay} / 60` minutes)." 
  echo "Errors are expected until the condition is satisfied"
  while : ; do
    value=`oc get ${resourceName} -o json | jq -r "${jqStatement}"`
    if [ "$value" = "$testValue" ]; then
      echo "Attempt #`expr ${attempt} + 1`/${attempts}: Success - Resource ${resourceName} met the condition"
      break
    else
      echo "Attempt #`expr ${attempt} + 1`/${attempts}: Waiting for condition to be satisfied"
    fi
    attempt=$((attempt+1))
    if ((attempt == attempts)); then
      echo "Failed - Resource '${resourceName}' didn't meat the condition on time, you need to troubleshoot"
      exit 1
    fi
    sleep $delay
  done
}

wait_for_k8s_log_occurrence () {
  local resourceName="${1}"
  local testValue="${2}"
  local attempts="${3:-${DEFAULT_ATTEMPTS}}"
  local delay="${4:-${DEFAULT_DELAY}}"

  local attempt=0
  echo "Waiting on resource '${resourceName}' for log to contain value '${testValue}' with '${attempts}' attempts with '${delay}' seconds delay each (total of `expr ${attempts} \* ${delay} / 60` minutes)." 
  echo "Errors are expected until the condition is satisfied"
  while : ; do
    oc logs ${resourceName} | grep "${testValue}"
    status=$?
    if [ "$status" = "0" ]; then
      echo "Attempt #`expr ${attempt} + 1`/${attempts}: Success - Resource ${resourceName} met the condition"
      break
    else
      echo "Attempt #`expr ${attempt} + 1`/${attempts}: Waiting for condition to be satisfied"
    fi
    attempt=$((attempt+1))
    if ((attempt == attempts)); then
      echo "Failed - Resource '${resourceName}' didn't meat the condition on time, you need to troubleshoot"
      exit 1
    fi
    sleep $delay
  done
}

wait_for_k8s_resource_condition () {
  local resourceName="${1}"
  local conditionName="${2}"
  local attempts="${3:-${DEFAULT_ATTEMPTS}}"
  local delay="${4:-${DEFAULT_DELAY}}"
  wait_for_k8s_resource_condition_generic $resourceName '.status.conditions[] | select(.type == "'$conditionName'") | .status' True $attempts $delay
}

wait_for_k8s_resource_disappear () {
  local resourceName="${1}"
  local attempts="${2:-${DEFAULT_ATTEMPTS}}"
  local delay="${3:-${DEFAULT_DELAY}}"
  
  local attempt=0
  echo "Waiting on resource '${resourceName}' to disappear with '${attempts}' attempts with '${delay}' seconds delay each (total of `expr ${attempts} \* ${delay} / 60` minutes)." 
  echo "Successes are expected until the resource '${resourceName}' disappears"
  while : ; do
    echo "Attempt #`expr ${attempt} + 1`/${attempts}: " 
    ! oc get ${resourceName} && echo "Success - Resource ${resourceName} disappeared" && break
    attempt=$((attempt+1))
    if ((attempt == attempts)); then
      echo "Failed - Resource '${resourceName}' didn't disappear, you need to troubleshoot"
      exit 1
    fi
    sleep $delay
  done
}

add_db2mc_connection() {
  local db_name="${1}"

  echo
  echo "Adding DB '${db_name}' to DB2MC"
  curl -k -X POST \
  https://db2mc.${OCP_APPS_ENDPOINT}/dbapi/v4/dbprofiles \
  -H "authorization: Bearer ${AUTH_TOKEN}" \
  -H 'content-type: application/json' \
  -d '{"host":"'${DB2_HOSTNAME}'","port":"50000","databaseName":"'${db_name}'",
  "dataServerType":"DB2LUW","name":"'${db_name}'",
  "operationCred":{"user":"db2inst1","password":"'${UNIVERSAL_PASSWORD}'",saveOperationCred:"true"},
  "sslConnection":"false"}'
}

remove_db2mc_connection() {
  local db_name="${1}"

  echo
  echo "Removing DB '${db_name}' from DB2MC"
  curl -k -X DELETE \
  https://db2mc.${OCP_APPS_ENDPOINT}/dbapi/v4/dbprofiles/${db_name} \
  -H "authorization: Bearer ${AUTH_TOKEN}" \
  -H 'content-type: application/json' 
}

wait_for_cp4ba() {
  local resourceName="${1}"
  local attempts="${2:-60}"
  local delay="${3:-60}"
  
  local attempt=0
  echo
  echo "Waiting for CP4BA to finish deployment with '${attempts}' attempts with '${delay}' seconds delay each (total of `expr ${attempts} \* ${delay} / 60` minutes)." 
  while : ; do
    echo 
    echo ">>>>$(print_timestamp) Attempt #`expr ${attempt} + 1`/${attempts}: Checking if CP4BA is deployed"

    value=`oc get ICP4ACluster/${resourceName} -o json | jq -r '.status.conditions[] | select(.type == "ReconciliationSuccess") | .status'`
    echo
    echo ">>>>$(print_timestamp) Current status of ReconciliationSuccess is: ${value}"

    notready_pods=`oc get pods -o json  | \
    jq -r '.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded" and .status.phase != "Failed" and ([ .status.conditions[] | select(.type == "Ready" and .status != "True") ] | length ) == 1 ) | .metadata.name'`
    
    if [ -z "$notready_pods" ]; then
      echo
      echo ">>>>$(print_timestamp) All current Pods are Ready"
    else
      echo
      echo ">>>>$(print_timestamp) Some Pods are still not ready:"
      echo ${notready_pods}
    fi

    reconciliation_message=`oc get ICP4ACluster/${resourceName} -o json | jq -r '.status.conditions[] | select(.type == "ReconciliationSuccess") | .message'`
    echo
    echo ">>>>$(print_timestamp) Current message of ReconciliationSuccess is: ${reconciliation_message}"

    echo
    echo ">>>>$(print_timestamp) Completed if ReconciliationSuccess is True, all Pods are Ready and message is empty"
    
    if [ "$value" = "True" ] && [ -z "$notready_pods" ] && [ -z "$reconciliation_message" ]; then
      echo ">>>>$(print_timestamp) Deployment completed"
      break
    else
      echo ">>>>$(print_timestamp) Completed condition not yet met, waiting for ${delay} seconds before trying again"
    fi

    attempt=$((attempt+1))
    if ((attempt == attempts)); then
      echo ">>>>$(print_timestamp) Failed - Completed conditions not met, you need to troubleshoot"
      exit 1
    fi
    sleep $delay
  done
}

exit_test() {
  local exit_code="${1}"
  local fail_message="${2:-Failed}"

  if [[ "$exit_code" != "0" ]]; then
    echo ">>>>$(print_timestamp) ${fail_message}"
    exit $exit_code
  fi
}

print_timestamp() {
  date --utc +%FT%TZ
}