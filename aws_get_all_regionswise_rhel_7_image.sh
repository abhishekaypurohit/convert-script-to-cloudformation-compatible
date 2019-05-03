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


#as of Dec 6 2018:
#ap-south-1:ami-09a4d6a78af9e9a73
#eu-west-3:ami-0da6335c8dff5d55a
#eu-west-2:ami-0b1eb35fb81061601
#eu-west-1:ami-0b5171a7b859ff1b4
#ap-northeast-2:ami-07be38aae5985872f
#ap-northeast-1:ami-08419d23bf91152e4
#sa-east-1:ami-071ceb2e9e4b0ae06
#ca-central-1:ami-0c896f6be8b26325e
#ap-southeast-1:ami-01b02e6dd3efebd61
#ap-southeast-2:ami-08d099ec55a5c5a16
#eu-central-1:ami-00e37cffd3bb3ac8d
#us-east-1:ami-0e3688b4a755ad736
#us-east-2:ami-0302c1ecc74930ba5
#us-west-1:ami-0ec1ad91f200c15a8
#us-west-2:ami-0e00026dd0f3688e2