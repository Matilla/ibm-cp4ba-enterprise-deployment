#!/bin/bash

# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployment-installing-enterprise-script

echo
echo ">>>>Source internal variables"
. ../inernal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) CP4BA deploy install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Make helper scripts executable"
chmod u+x data/add-pattern.sh
chmod u+x data/add-component.sh

echo
echo ">>>>$(print_timestamp) Update Base CR"
sed -f - data/cr.yaml > data/cr.target.yaml << SED_SCRIPT
s|{{CP4BA_CR_META_NAME}}|${CP4BA_CR_META_NAME}|g
s|{{CP4BA_VERSION}}|${CP4BA_VERSION}|g
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
s|{{DEPLOYMENT_PLATFORM}}|${DEPLOYMENT_PLATFORM}|g
s|{{LDAP_HOSTNAME}}|${LDAP_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Resource Registry (RR) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-checking-cluster-configuration point 3
./data/add-pattern.sh data/cr.target.yaml "foundation"
yq m -i -x -a append data/cr.target.yaml data/rr/cr.yaml

echo
echo ">>>>$(print_timestamp) User Management Services (UMS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-user-management-services

echo
echo ">>>>$(print_timestamp) Update UMS CR"
sed -f - data/ums/cr.yaml > data/ums/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add UMS to CR"
./data/add-pattern.sh data/cr.target.yaml "foundation"
./data/add-component.sh data/cr.target.yaml "ums"
yq m -i -x -a append data/cr.target.yaml data/ums/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Navigator (BAN) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-navigator

echo
echo ">>>>$(print_timestamp) Update BAN CR"
sed -f - data/ban/cr.yaml > data/ban/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
s|{{MAIL_HOSTNAME}}|${MAIL_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add BAN to CR"
./data/add-pattern.sh data/cr.target.yaml "foundation"
yq m -i -x -a append data/cr.target.yaml data/ban/cr.target.yaml

if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
  echo 
  echo ">>>>$(print_timestamp) Add BAN Google IDP configuration"
  yq w -i data/cr.target.yaml spec.navigator_configuration.icn_production_setting.jvm_customize_options \
  "DELIM=;-Dcom.filenet.authentication.ExShareGID.AuthTokenOrder=oidc,oauth,ltpa"
fi

echo
echo ">>>>$(print_timestamp) Business Automation Studio (BAS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-studio

echo
echo ">>>>$(print_timestamp) Update BAS CR"
sed -f - data/bas/cr.yaml > data/bas/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add BAS to CR"
./data/add-pattern.sh data/cr.target.yaml "foundation"
./data/add-component.sh data/cr.target.yaml "bas"
yq m -i -x -a append data/cr.target.yaml data/bas/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Insights (BAI) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-insights

echo
echo ">>>>$(print_timestamp) Add BAI to CR"
./data/add-pattern.sh data/cr.target.yaml "foundation"
./data/add-component.sh data/cr.target.yaml "bai"
yq m -i -x -a append data/cr.target.yaml data/bai/cr.yaml

echo
echo ">>>>$(print_timestamp) Operational Decision Manager (ODM) (decisions pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-operational-decision-manager

echo
echo ">>>>$(print_timestamp) Update ODM CR"
sed -f - data/odm/cr.yaml > data/odm/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add ODM to CR"
./data/add-pattern.sh data/cr.target.yaml "decisions"
./data/add-component.sh data/cr.target.yaml "decisionCenter"
./data/add-component.sh data/cr.target.yaml "decisionRunner"
./data/add-component.sh data/cr.target.yaml "decisionServerRuntime"
yq m -i -x -a append data/cr.target.yaml data/odm/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Automation Decision Services (ADS) (decisions_ads pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-automation-decision-services

echo
echo ">>>>$(print_timestamp) Add ADS to CR"
./data/add-pattern.sh data/cr.target.yaml "decisions_ads"
./data/add-component.sh data/cr.target.yaml "ads_designer"
./data/add-component.sh data/cr.target.yaml "ads_runtime"
yq m -i -x -a append data/cr.target.yaml data/ads/cr.yaml

echo
echo ">>>>$(print_timestamp) FileNet Content Manager (FNCM) (content pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-filenet-content-manager

echo
echo ">>>>$(print_timestamp) Update FNCM CR"
sed -f - data/fncm/cr-cpe.yaml > data/fncm/cr-cpe.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add FNCM to CR"
./data/add-pattern.sh data/cr.target.yaml "content"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-cpe.target.yaml
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-graphql.yaml
./data/add-component.sh data/cr.target.yaml "cmis"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-cmis.yaml
./data/add-component.sh data/cr.target.yaml "css"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-css.yaml
./data/add-component.sh data/cr.target.yaml "es"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-es.yaml
./data/add-component.sh data/cr.target.yaml "tm"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-tm.yaml

if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
  echo
  echo ">>>>$(print_timestamp) Add Google TLS and IDP configuration to CR"
  yq w -i data/cr.target.yaml spec.shared_configuration.trusted_certificate_list[+] "google-tls"
  yq m -i -x -a append data/cr.target.yaml data/fncm/cr-es-gid.yaml
fi

echo
echo ">>>>$(print_timestamp) Automation Application Engine (AAE) (application pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-application

echo
echo ">>>>$(print_timestamp) Update AAE CR"
sed -f - data/aae/cr.yaml > data/aae/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT
sed -f - data/aae/cr-persistence.yaml > data/aae/cr-persistence.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add AAE to CR"
./data/add-pattern.sh data/cr.target.yaml "application"
./data/add-component.sh data/cr.target.yaml "app_designer"
./data/add-component.sh data/cr.target.yaml "ae_data_persistence"
yq m -i -x -a append data/cr.target.yaml data/aae/cr.target.yaml
yq m -i -x -a append data/cr.target.yaml data/aae/cr-persistence.target.yaml
yq w -i data/cr.target.yaml spec.application_engine_configuration[0].data_persistence.enable "true"

echo
echo ">>>>$(print_timestamp) Automation Document Processing (ADP) (document_processing pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-document-processing

echo
echo ">>>>$(print_timestamp) Update ADP CR"
sed -f - data/adp/cr.yaml > data/adp/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add ADP to CR"
./data/add-pattern.sh data/cr.target.yaml "document_processing"
./data/add-component.sh data/cr.target.yaml "document_processing_designer"
yq m -i -x -a append data/cr.target.yaml data/adp/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Workflow Authoring (BAWAUT)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-workflow-authoring

echo
echo ">>>>$(print_timestamp) Update BAWUAT CR"
sed -f - data/bawaut/cr.yaml > data/bawaut/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add BAWAUT to CR"
./data/add-pattern.sh data/cr.target.yaml "workflow"
./data/add-component.sh data/cr.target.yaml "baw_authoring"
yq m -i -x -a append data/cr.target.yaml data/bawaut/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Apply completed CR"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=script-deploying-custom-resource
oc apply -f data/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for CP4BA deployment to complete, this will take hours"
#wait_for_cp4ba ${CP4BA_CR_META_NAME} ${CP4BA_ATTEMPTS} ${CP4BA_DELAY}

echo
echo ">>>>$(print_timestamp) Wait for Zen instance Ready state"
wait_for_k8s_resource_condition Cartridge/icp4ba Ready ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for UMS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ums-deployment Available ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for BAS PB Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-pbk-ae-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAS JMS StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-bastudio-authoring-jms ".status.readyReplicas" 1 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-bastudio-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM CPE Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cpe-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM CSS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-css-deploy-1 Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM CMIS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cmis-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM GraphQL Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-graphql-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM ES Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-es-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM TM Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-tm-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Mongo Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-mongo-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Git Gateway Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-gitgateway-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP CDRA Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cdra-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Viewone Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-viewone-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP CPDS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cpds-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP CDS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cds-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAN Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-navigator-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Redis StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-redis-ha-server ".status.readyReplicas" 3 ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for ADP RabbitMQ StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-rabbitmq-ha ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP NL extractor Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-natural-language-extractor Available ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for ADP NL extractor Pod Ready state (Not waiting for each individual ADP CA pod)"
echo ">>>>$(print_timestamp) ADP CA pods take long time to pull images on first deployment"
# Also waiting on pod because Deployment becomes available even when the pod is not ready due to extra long image pulling time
nl_extract_pod=`oc get pod -o name | grep natural-language-extractor | head -n 1`
wait_for_k8s_resource_condition ${nl_extract_pod} Ready ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for BAI Management Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-bai-management Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAI BPC Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-bai-business-performance-center Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for MLS ITP Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-mls-itp Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for MLS WFI Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-mls-wfi Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM DC Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisioncenter Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM DS Runtime Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisionserverruntime Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM DS Console Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisionserverconsole Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM Decision Runner Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisionrunner Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for AAE Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-instance1-aae-ae-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for PFS StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-pfs ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAWAUT StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-workflow-authoring-baw-server ".status.readyReplicas" 1 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADS runtime service Deployment Available state (Not waiting for each individual ADS pod)"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-runtime-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

wait_for_cp4ba ${CP4BA_CR_META_NAME} ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) CP4BA deploy install completed"
