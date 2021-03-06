#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/solr_query_functions.sh

set_genotype-phenotype_core_url()
{
    core_url='https://www.ebi.ac.uk/mi/impc/solr/genotype-phenotype/select';
}

set_jq_filter_attributes_for_phenotypes()
{
    jq_filter_attributes='"assertion_type": .assertion_type,
                          "assertion_type_id": .assertion_type_id,
                          "mp_term_id": .mp_term_id,
                          "mp_term_name": .mp_term_name,
                          "top_level_mp_term_ids": [.top_level_mp_term_id[]?] | join("|"),
                          "top_level_mp_term_names": [.top_level_mp_term_name[]?] | join("|"),
                          "intermediate_mp_term_ids": [.intermediate_mp_term_id[]?] | join("|"),
                          "intermediate_mp_term_names": [.intermediate_mp_term_name[]?] | join("|"),
                          "marker_symbol": .marker_symbol,
                          "marker_accession_id": .marker_accession_id,
                          "colony_id": .colony_id,
                          "allele_name": .allele_name,
                          "allele_symbol": .allele_symbol,
                          "allele_accession_id": .allele_accession_id,
                          "strain_name": .strain_name,
                          "strain_accession_id": .strain_accession_id,
                          "phenotyping_center": .phenotyping_center,
                          "project_name": [.project_name[]?] | join("|"),
                          "resource_name": .resource_name,
                          "sex": .sex,
                          "zygosity": .zygosity,
                          "pipeline_name": .pipeline_name,
                          "pipeline_stable_id": .pipeline_stable_id,
                          "procedure_name": .procedure_name,
                          "procedure_stable_id": [.procedure_stable_id[]?] | join("|"),
                          "parameter_name": .parameter_name,
                          "parameter_stable_id": .parameter_stable_id,
                          "statistical_method": .statistical_method,
                          "p_value": .p_value,
                          "effect_size": .effect_size,
                          "life_stage_acc": .life_stage_acc,
                          "life_stage_name": .life_stage_name';

}

obtain_phenotype_data()
{
    set_genotype-phenotype_core_url;
    
    query_string='?q=*:*&fq=marker_symbol:*%20AND%20mp_term_id:*%20AND%20resource_name:IMPC%20AND%20life_stage_name:%22Early%20adult%22';
    
    set_jq_filter_attributes_for_phenotypes;
    
    documents_per_request=1000
    
    output_filename='impc_phenotype_data.tsv';
    
    process_parameter "$core_url" "$query_string" "$jq_filter_attributes" $documents_per_request "$output_filename";

}

obtain_phenotype_data