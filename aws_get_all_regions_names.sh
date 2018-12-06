#!/usr/bin/env bash

aws ec2 describe-regions --filters "Name=endpoint,Values=*" | grep 'RegionName' | awk '{ print $2}' | tr -d '"'