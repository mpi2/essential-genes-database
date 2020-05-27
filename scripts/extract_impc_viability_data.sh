#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/solr_query_functions.sh

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

obtain_embryo_viability_data()
{
    set_experiment_core_url;
    
    query='?q=parameter_stable_id:';
    
    declare -a paramenter_stable_ids=("IMPC_EVL_001_001" "IMPC_EVM_001_001" "IMPC_EVO_001_001" "IMPC_EVP_001_001");
    
    set_jq_filter_attributes_for_viability;
    
    documents_per_request=1000
    
    output_filename='embryo_viability.tsv';
    
    for id in "${paramenter_stable_ids[@]/#/$query}";
    do
        query_string="$id";
        echo "$query_string"
        process_parameter "$core_url" "$query_string" "$jq_filter_attributes" $documents_per_request "$output_filename";
    done
}

obtain_adult_viability_data()
{
    set_experiment_core_url;
    
    query='?q=parameter_stable_id:';
    
    declare -a paramenter_stable_ids=("IMPC_VIA_001_001");
    
    set_jq_filter_attributes_for_viability;
    
    documents_per_request=1000
    
    output_filename='adult_viability.tsv';
    
    for id in "${paramenter_stable_ids[@]/#/$query}";
    do
        query_string="$id";
        echo "$query_string"
        process_parameter "$core_url" "$query_string" "$jq_filter_attributes" $documents_per_request "$output_filename";
    done
}

obtain_embryo_viability_data
obtain_adult_viability_data
