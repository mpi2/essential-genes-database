#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/solr_query_functions.sh


set_statistical-result_core_url()
{
    core_url='https://www.ebi.ac.uk/mi/impc/solr/statistical-result/select';
}


set_jq_filter_attributes_for_proceedure_data()
{
    jq_filter_attributes='.value as $centre | .pivot[]| { "centre": $centre, "procedure_stable_id": .value, "procedure_count": .count }';

}


obtain_proceedure_data()
{
    set_statistical-result_core_url;
    
    query_string='?q=status:Success%20AND%20resource_name:IMPC&facet=true&facet.pivot=phenotyping_center,procedure_stable_id&rows=0';
    
    set_jq_filter_attributes_for_proceedure_data;
    
    output_filename='impc_proceedures_by_centre.tsv';
    
    process_facet_pivot_query "$core_url" "$query_string" "$jq_filter_attributes" "$output_filename";

}


obtain_proceedure_data