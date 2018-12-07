#!/usr/bin/env bash


# look here : https://access.redhat.com/solutions/15356

out="$(aws ec2 describe-regions --filters "Name=endpoint,Values=*" | grep 'RegionName' | awk '{ print $2}' | tr -d '"' | tr '\n' ' ')"

# if only US Images
#out="$(aws ec2 describe-regions --filters "Name=endpoint,Values=*us*" | grep 'RegionName' | awk '{ print $2}' | tr -d '"' | tr '\n' ' ')"


regions=($out)

for ix in ${!regions[*]}
do
    r=${regions[$ix]}

    imageid="$(aws --region $r ec2 describe-images \
    --owners 309956199498 \
    --filters 'Name=name,Values=*RHEL-7*_HVM_GA*' 'Name=state,Values=available' \
    --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')"

    echo $r:$imageid

done
