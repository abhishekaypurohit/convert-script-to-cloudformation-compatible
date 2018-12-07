#!/usr/bin/env bash

# getting all regions just names.
aws ec2 describe-regions --filters "Name=endpoint,Values=*" | grep 'RegionName' | awk '{ print $2}' | tr -d '"'


#will produce output as :
# ap-south-1
# eu-west-3
# eu-west-2
# eu-west-1
# ap-northeast-2
# ap-northeast-1
# sa-east-1
# ca-central-1
# ap-southeast-1
# ap-southeast-2
# eu-central-1
# us-east-1
# us-east-2
# us-west-1
# us-west-2

