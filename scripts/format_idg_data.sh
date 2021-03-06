#!/bin/bash
set -e

printf '%s' IDG_TargetList_CurrentVersion.json | \
    jq  --raw-output '(map(keys) | add | unique) as $keys | 
                      map([.[ $keys[] ]|tostring])[] | 
                      @tsv' > idg_target_list_current_version.tsv
    			      
    