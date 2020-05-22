#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/solr_query_functions.sh

set_stats_core_url()
{
    core_url='https://www.ebi.ac.uk/mi/impc/solr/statistical-result/select';
}

set_jq_filter_attributes()
{
    jq_filter_attributes='"doc_id": .doc_id,
                          "db_id": .db_id,
                          "data_type": .data_type,
                          "mp_term_id": .mp_term_id,
                          "mp_term_name": .mp_term_name,
                          "top_level_mp_term_ids": [.top_level_mp_term_id[]?] | join("|"),	
                          "top_level_mp_term_names": [.top_level_mp_term_name[]?] | join("|"),	
                          "life_stage_acc": .life_stage_acc,
                          "life_stage_name": .life_stage_name,
                          "project_name": .project_name,
                          "phenotyping_center": .phenotyping_center,
                          "pipeline_stable_id": .pipeline_stable_id,
                          "pipeline_stable_key": .pipeline_stable_key,
                          "pipeline_name": .pipeline_name,
                          "pipeline_id": .pipeline_id,
                          "procedure_stable_id": .procedure_stable_id,
                          "procedure_stable_key": .procedure_stable_key,
                          "procedure_name": .procedure_name,
                          "procedure_id": .procedure_id,
                          "parameter_stable_id": .parameter_stable_id,
                          "parameter_stable_key": .parameter_stable_key,
                          "parameter_name": .parameter_name,
                          "parameter_id": .parameter_id,
                          "colony_id": .colony_id,
                          "marker_symbol": .marker_symbol,
                          "marker_accession_id": .marker_accession_id,
                          "allele_symbol": .allele_symbol,
                          "allele_name": .allele_name,
                          "allele_accession_id": .allele_accession_id,
                          "strain_name": .strain_name,
                          "strain_accession_id": .strain_accession_id,
                          "genetic_background": .genetic_background,
                          "zygosity": .zygosity,
                          "status": .status,
                          "p_value": .p_value,
                          "significant": .significant';

}

obtain_stats_data()
{
    set_stats_core_url;
    
    query_string='?q=*:*&fq=marker_symbol:*%20AND%20status:Success%20AND%20project_name:IMPC%20AND%20mp_term_id:*%20AND%20zygosity:homozygote%20AND%20life_stage_name:%22Early%20adult%22';

    set_jq_filter_attributes;
    
    # This number is set low to keep the memory used by the script down.
    # The script will make many requests to the solr server, 
    # but in tests did not take much longer to complete than one making 10x fewer requests.   
    documents_per_request=5000
    
    output_filename='impc_stats_data.tsv';
    
    process_parameter "$core_url" "$query_string" "$jq_filter_attributes" $documents_per_request "$output_filename";

}

obtain_stats_data