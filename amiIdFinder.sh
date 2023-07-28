#!/bin/bash

if [ -z "$1" ] ; then
    echo "Please pass the ID of the AMI"
    exit 1
fi

AMI_ID="${1}"

# Function to get the AMI name from ID
get_ami_name() {
    aws ec2 describe-images --image-ids ${AMI_ID} --query 'Images[*].[Name]' --output text
}

# Get the AMI name from the provided ID
AMI_NAME=$(get_ami_name)

if [ -z "${AMI_NAME}" ]; then
    echo "No AMI found with ID \"${AMI_ID}\""
    exit 1
fi

echo "AMI Name: ${AMI_NAME}"

# Function to find AMI ID from name in a specific region
find_ami_id_by_name_in_region() {
    local region="$1"
    aws ec2 describe-images --query 'Images[*].[ImageId]' --filters "Name=name,Values=${AMI_NAME}" --region ${region} --output text
}

declare -a REGIONS=($(aws ec2 describe-regions --output json | jq -r '.Regions[].RegionName'))

for r in "${REGIONS[@]}"; do
    if [ "${r}" != "$(aws configure get region)" ]; then
        AMI_ID_IN_REGION=$(find_ami_id_by_name_in_region "${r}")
        if [ -n "${AMI_ID_IN_REGION}" ]; then
            echo "\"${r}\" = \"${AMI_ID_IN_REGION}\""
        fi
    fi
done