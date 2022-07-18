#!/bin/bash

cd $WORKING_DIRECTORY

TMP_DIR=${TMP_DIR:-/app}


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

# run plan
terraform plan -input=false -no-color -out $TMP_DIR/tfplan.binary 2>&1 | tee $TMP_DIR/tfplan.log
if [[ $? == 0 ]];
then
    PLAN_CHECK="✅"
else
    PLAN_CHECK="❌"
fi

# convert to json
terraform show -json -no-color $TMP_DIR/tfplan.binary | jq '.' > $TMP_DIR/tfplan.json

if [[ "$ACTION_MODE" == "plan" ]];
then
        
    # formatted outputs
    python3 $TMP_DIR/main.py -f $TMP_DIR/tfplan.log -o $TMP_DIR/summary.txt -t log
    python3 $TMP_DIR/main.py -f $TMP_DIR/results_json.json -o $TMP_DIR/checkov.md -t scan
    python3 $TMP_DIR/main.py -f $TMP_DIR/tfplan.json -o $TMP_DIR/tfplan.md -t plan
    
    cat <<EOT > $TMP_DIR/PPRINTOUT.txt
### Step Checks
#### ${FORMAT_CHECK} - 🖌 Terraform Format and Style
#### ${INIT_CHECK} - ⚙️ Terraform Initialization
#### ${PLAN_CHECK} - 📖 Terraform Plan