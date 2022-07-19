#!/bin/bash


################## Get Changed files ###############
# Pull Request
git fetch origin "${{ github.base_ref }}" --depth=1
# Get the list of all changed resources
diff_result=$(git diff --name-only "origin/${{ github.base_ref }}" ${{ github.sha }} )
echo "Diff between origin/${{ github.base_ref }} and ${{ github.sha }}"
# Extract terraform's files
terraform_files=$(echo $diff_result | tr -s '[[:space:]]' '\n' | grep -o '.*\.tf$')
echo "Changed Terraform's files: $terraform_files"
#extract folders where the changed teraforms files are stored
#and create json to proceed them in the matrix style
matrix_output="{\"include\":[ "
for line in in $terraform_files
do 
  if [[ $line == *".tf"* ]];
  then
    echo "Working line: $line" 
    dir=$(dirname $line) 
    echo "extracted dir: $dir"
    matrix_output="$matrix_output{\"folder\":\"$dir\"},"
  fi
done
matrix_output="$matrix_output ]}"
echo "Prepared working matrix: $matrix_output"
echo "::set-output name=matrix::${matrix_output}"


################## END: Get Changed files ###############

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