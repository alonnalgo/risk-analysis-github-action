#!/bin/sh
set -e

# create terraform environment
if [[ "$TF_VERSION" == "latest"  || "$TF_VERSION" == "" ]];
then
    tfswitch --latest
else
    tfswitch
fi

# setup configuration file if token is passed
if [[ "TF_TOKEN" != "" ]];
then
    
    cat <<EOT > ~/.terraformrc
credentials "${TF_HOST}" {
    token = "${TF_TOKEN}"
}
EOT
    echo "Created .terraformrc file."
fi

# format check
terraform fmt -check -recursive
if [[ $? == 0 ]];
then
    FORMAT_CHECK="✅"
else
    FORMAT_CHECK="❌"
fi

# initialize terraform
terraform init
if [[ $? == 0 ]];
then
    INIT_CHECK="✅"
else
    INIT_CHECK="❌"
fi
