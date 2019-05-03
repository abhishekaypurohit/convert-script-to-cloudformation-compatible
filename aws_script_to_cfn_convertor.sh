#!/usr/bin/env bash

#each line first char should e double quote
#each line should ends with [\n"]
#any double quote encounter then replace it with [\"]
#leave single quote as is


uses="./aws_cfn_convertor.sh <input file> <optional output file, if not provided then inputfile.txt will be created"

input_file=$1
output_file=$2

( [[ -z "$input_file" ]] ) && echo $uses && exit 1;

if [[ -z "$output_file" ]]; then
    output_file="$input_file".txt
fi

out="$(cp $input_file $output_file)"

out="$(sed -i s/\"/\\\\\"/g "$output_file")"


out="$(sed -i s/^/\"/g "$output_file")"

out="$(sed -i s/$/\\\\\n\",/g "$output_file")"

# escape any slash


# remove comma from last line
out="$(sed -i '$ s/,$//g' $output_file)"






