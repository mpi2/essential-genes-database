#!/bin/bash
set -e

error_exit()
{
    printf '%s\n' "$1" 1>&2;
    exit 1;
}

check_http_status_code()
{
    json_response_with_status="$1"
    
    # The status was included as the last 3 characters of the response string
    # The status is extracted using the method outlined here:
    # https://stackoverflow.com/questions/19858600/accessing-last-x-characters-of-a-string-in-bash
    # This version works with responses of less than 3 characters
    # rather than the simpler ${json_response_with_status:(-3)}
    
    status=${json_response_with_status:${#json_response_with_status}<3?0:-3}
    
    if [ "$status" != "200" ]; then
          error_exit "A *""$status""* response was received from the server.";
    fi;
}


fetch_data()
{
    if [ "$#" -ne 2 ]; then
        error_exit "Usage: fetch_data url output_filename";
    fi;
    
    # Obtain the status code with the response
    # see : https://stackoverflow.com/questions/38906626/curl-to-return-http-status-code-along-with-the-response
    
    data=$(curl -sSLN -w "%{http_code}" "$1")
    check_http_status_code "$data"
    
    # Remove the 200 status code from the end of the response and process
    json=${data%200}
    
    printf '%s' $json | \
    jq  --raw-output '(map(keys) | add | unique) as $keys | 
                      map([.[ $keys[] ]|tostring])[] | 
                      @tsv' >> "$2";
}

IDG_DATA_URL='https://raw.githubusercontent.com/druggablegenome/IDGTargets/master/IDG_TargetList_CurrentVersion.json';

fetch_data "${IDG_DATA_URL}" "idg_target_list.tsv"