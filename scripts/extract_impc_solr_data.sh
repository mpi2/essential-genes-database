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

set_experiment_core_url()
{
    core_url='https://www.ebi.ac.uk/mi/impc/solr/experiment/select';
}

set_jq_filter_attributes_for_viability()
{
    jq_filter_attributes='"parameter_stable_id": .parameter_stable_id,
            "project_id": .project_id,
            "project_name": .project_name,
            "procedure_group": .procedure_group,
            "procedure_stable_id": .procedure_stable_id,
            "pipeline_stable_id": .pipeline_stable_id,
            "pipeline_name": .pipeline_name,
            "phenotyping_center_id": .phenotyping_center_id,
            "phenotyping_center": .phenotyping_center,
            "developmental_stage_acc": .developmental_stage_acc,
            "developmental_stage_name": .developmental_stage_name,
            "gene_symbol": .gene_symbol,
            "gene_accession_id": .gene_accession_id,
            "colony_id": .colony_id,
            "biological_sample_group": .biological_sample_group,
            "experiment_source_id": .experiment_source_id,
            "allele_accession_id": .allele_accession_id,
            "allele_symbol": .allele_symbol,
            "allelic_composition": .allelic_composition,
            "genetic_background": .genetic_background,
            "strain_accession_id": .strain_accession_id,
            "strain_name": .strain_name,
            "zygosity": .zygosity,
            "sex": .sex,
            "category": .category,
            "parameter_name": .parameter_name,
            "procedure_name": .procedure_name';

}

fetch_data()
{
    if [ "$#" -ne 3 ]; then
        error_exit "Usage: fetch_data url jq_filter_attributes output_filename";
    fi;
    
    # Obtain the status code with the response
    # see : https://stackoverflow.com/questions/38906626/curl-to-return-http-status-code-along-with-the-response
    
    data=$(curl -sSLN -w "%{http_code}" "$1")
    check_http_status_code "$data"
    
    # Remove the 200 status code from the end of the response and process
    json=${data%200}
    
    printf '%s' $json | \
    jq '[.response .docs[] |
        { '"$2"'
        }]' |
    jq -r '(.[0] | keys_unsorted) as $keys |
            map([.[ $keys[] ]])[] |
            @tsv' >> "$3";
    sleep 1;
}

process_parameter()
{
    if [ "$#" -ne 4 ]; then
        error_exit "Usage: process_parameter solr_core_url query_string jq_filter_attributes output_filename.";
    fi
    
    core_url="$1"
    query="$2"
    jq_filter_attributes="$3"
    output="$4"
    
    num=$(curl -sSLN "$core_url""$query"'&rows=0' | jq '.response.numFound')
    step=500
    
    if [ "$num" != "" ]; then
    
      if [ "$num" -gt "$step" ]; then
    
          for i in $(seq 0 $step $num);
          do
              url="$core_url""$query"'&start='"$i"'&rows='"$step";
              fetch_data "$url" "$jq_filter_attributes" "$output";
          done
    
      else
          url="$core_url""$query"'&start=0&rows='"$step";
          fetch_data "$url" "$jq_filter_attributes" "$output";
      fi;
    
    
    else
      error_exit "Failed to obtain the number of documents from the Solr server";
    
    fi;
}

obtain_embryo_viability_data()
{
    set_experiment_core_url;
    
    query='?q=parameter_stable_id:';
    
    declare -a paramenter_stable_ids=("IMPC_EVL_001_001" "IMPC_EVM_001_001" "IMPC_EVO_001_001" "IMPC_EVP_001_001");
    
    set_jq_filter_attributes_for_viability;
    
    output_filename='embryo_viability.tsv';
    
    for id in "${paramenter_stable_ids[@]/#/$query}";
    do
        query_string="$id";
        echo "$query_string"
        process_parameter "$core_url" "$query_string" "$jq_filter_attributes" "$output_filename";
    done
}

obtain_adult_viability_data()
{
    set_experiment_core_url;
    
    query='?q=parameter_stable_id:';
    
    declare -a paramenter_stable_ids=("IMPC_VIA_001_001" "IMPC_VIA_002_001");
    
    set_jq_filter_attributes_for_viability;
    
    output_filename='adult_viability.tsv';
    
    for id in "${paramenter_stable_ids[@]/#/$query}";
    do
        query_string="$id";
        echo "$query_string"
        process_parameter "$core_url" "$query_string" "$jq_filter_attributes" "$output_filename";
    done
}

obtain_embryo_viability_data
obtain_adult_viability_data