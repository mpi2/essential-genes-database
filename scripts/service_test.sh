#!/bin/bash
set -e

DEBUG=false

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/solr_query_functions.sh

ENDPOINT='https://www.gentar.org/essential-genes-dev/v1/graphql'

for i in "$@"
do
case $i in
    -p|--production)
    ENDPOINT='https://www.gentar.org/essential-genes/v1/graphql'
    shift # past argument
    ;;
    -d|--dev)
    ENDPOINT='https://www.gentar.org/essential-genes-dev/v1/graphql'
    shift # past argument
    ;;
    -s=*|--service=*)
    ENDPOINT="${i#*=}"
    shift # past argument=value
    ;;
    --default)
    shift # past argument
    ;;
    *)
          # unknown option
    ;;
esac
done


process_query()
{
    if [ "$#" -ne 3 ]; then
        error_exit "Usage: process_query service_endpoint query expected_output";
    fi;

    query="$2"
    expected="$3"
    
    if [ "$DEBUG" = true ]; then
        echo "curl -sSLN -w "%{http_code}"  \"${ENDPOINT}\" -H \"Content-type: application/json\" -H \"cache-control: no-cache\" -X POST --data \"${query}\""
    fi
    
    data=$(curl -sSLN -w "%{http_code}" "${ENDPOINT}" -H "Content-type: application/json" -H "cache-control: no-cache" -X POST --data "${query}")
    check_http_status_code "$data"
    
    # Remove the 200 status code from the end of the response and process
    json=${data%200}
    if [ "$json" != "$expected" ]; then
    	echo "** Failed **"
        error_exit "The result: $json does not match the expected_output $expected";
    else
    	echo "Passed"
    fi
    
    printf '\n'

}

run_test()
{
    if [ "$#" -ne 2 ]; then
        error_exit "Usage: run_test query expected_output";
    fi;
    process_query "$ENDPOINT" "$1" "$2"
}


mouse_gene_test()
{
    echo "Mouse Gene Test"
    
    symbol="Tbx20"
    mgi_gene_acc_id="MGI:1888496"
    query='{ "query": "{mouse_gene(where: {symbol: {_eq: \"'"$symbol"'\" }}) {mgi_gene_acc_id}}" }'    
    expected_result='{"data":{"mouse_gene":[{"mgi_gene_acc_id":"'"$mgi_gene_acc_id"'"}]}}'
    run_test "$query" "$expected_result"
    
}

mouse_gene_synonym_test()
{
    echo "Mouse Gene Synonym Test"
    
    synonym="Fgf-8"
    mgi_gene_acc_id="MGI:99604"
    query='{ "query": "{mouse_gene_synonym(where: {synonym: {_eq: \"'"$synonym"'\" }}) {mgi_gene_acc_id}}" }'    
    expected_result='{"data":{"mouse_gene_synonym":[{"mgi_gene_acc_id":"'"$mgi_gene_acc_id"'"}]}}'
    run_test "$query" "$expected_result"
    
}

mouse_embryo_viability_test()
{
    echo "Mouse Embryo Viability Test"
    
    query='{ "query": "{impc_embryo_viability(distinct_on: developmental_stage_name, where: {developmental_stage_name: {_eq: \"E15.5\"}}) {developmental_stage_name}}" }'    
    expected_result='{"data":{"impc_embryo_viability":[{"developmental_stage_name":"E15.5"}]}}'
    run_test "$query" "$expected_result"
    
}

mouse_adult_viability_test()
{
    echo "Mouse Adult Viability Test"
    
    query='{ "query": "{impc_adult_viability(distinct_on: zygosity, where: {zygosity: {_eq: \"homozygote\"}}) {zygosity}}" }'    
    expected_result='{"data":{"impc_adult_viability":[{"zygosity":"homozygote"}]}}'
    run_test "$query" "$expected_result"
    
}

fusil_test()
{
    echo "FUSIL Test"
    
    symbol="Tbx20"
    query='{ "query": "{fusil(distinct_on: bin_code, order_by: {bin_code: asc}, where: {bin_code: {_in: [\"CL\", \"DL\", \"SV\", \"VP\"]}}) {bin_code}}" }'    
    expected_result='{"data":{"fusil":[{"bin_code":"CL"}, {"bin_code":"DL"}, {"bin_code":"SV"}, {"bin_code":"VP"}]}}'
    run_test "$query" "$expected_result"
    
}

human_gene_test()
{
    echo "Human Gene Test"
    
    symbol="TBX20"
    query='{ "query": "{human_gene(where: {symbol: {_eq: \"'"$symbol"'\" }}) {hgnc_acc_id}}" }'    
    expected_result='{"data":{"human_gene":[{"hgnc_acc_id":"HGNC:11598"}]}}'
    run_test "$query" "$expected_result"
    
}

human_gene_synonym_test()
{
    echo "Human Gene Synonym Test"
    
    synonym="AIGF"
    hgnc_acc_id="HGNC:3686"
    query='{ "query": "{human_gene_synonym(where: {synonym: {_eq: \"'"$synonym"'\" }}) {hgnc_acc_id}}" }'    
    expected_result='{"data":{"human_gene_synonym":[{"hgnc_acc_id":"'"$hgnc_acc_id"'"}]}}'
    run_test "$query" "$expected_result"
    
}

hgnc_gene_test()
{
    echo "HGNC Gene Test"
    
    symbol="TBX20"
    query='{ "query": "{hgnc_gene(where: {symbol: {_eq: \"'"$symbol"'\" }}) {locus_group}}" }'    
    expected_result='{"data":{"hgnc_gene":[{"locus_group":"protein-coding gene"}]}}'
    run_test "$query" "$expected_result"
    
}

idg_test()
{
    echo "IDG Test"
    
    query='{ "query": "{idg(distinct_on: tdl, where: {tdl: {_in: [\"Tbio\", \"Tchem\", \"Tclin\", \"Tdark\"]}}, order_by: {tdl: asc}) {tdl}}" }'    
    expected_result='{"data":{"idg":[{"tdl":"Tbio"}, {"tdl":"Tchem"}, {"tdl":"Tclin"}, {"tdl":"Tdark"}]}}'
    run_test "$query" "$expected_result"
    
}

clingen_test()
{
    echo "ClinGen Test"
    
    query='{ "query": "{clingen(distinct_on: triplosensitivity, where: {triplosensitivity: {_eq: \"Sufficient Evidence for Triplosensitivity\"}}) {triplosensitivity}}" }'    
    expected_result='{"data":{"clingen":[{"triplosensitivity":"Sufficient Evidence for Triplosensitivity"}]}}'
    run_test "$query" "$expected_result"
    
}

achilles_test()
{
    echo "Achilles Gene Effect Test"
    
    symbol="TBX20"
    query='{ "query": "{achilles_gene_effect(where: {human_gene: {symbol: {_eq: \"'"$symbol"'\"}}}) {entrez_acc_id}}" }'    
    expected_result='{"data":{"achilles_gene_effect":[{"entrez_acc_id":57057}]}}'
    run_test "$query" "$expected_result"
    
}

gnomad_test()
{
    echo "gnomAD pLoF Test"
    
    query='{ "query": "{gnomad_plof(distinct_on: gene_type, where: {gene_type: {_eq: \"protein_coding\"}}) {gene_type}}" }'    
    expected_result='{"data":{"gnomad_plof":[{"gene_type":"protein_coding"}]}}'
    run_test "$query" "$expected_result"
    
}

ortholog_support_count_test()
{
    echo "Ortholog Support Count Test"
    
    query='{ "query": "{ortholog_aggregate{aggregate{max {support_count}}}}" }'    
    expected_result='{"data":{"ortholog_aggregate":{"aggregate" : {"max" : {"support_count" : 12}}}}}'
    run_test "$query" "$expected_result"
    
}


mouse_tests()
{
    mouse_gene_test
    mouse_gene_synonym_test
    mouse_embryo_viability_test
    mouse_adult_viability_test
    fusil_test
}

human_tests()
{
    human_gene_test
    human_gene_synonym_test
    hgnc_gene_test
    idg_test
    clingen_test
    achilles_test
    gnomad_test
}

main()
{
    mouse_tests
    human_tests
    ortholog_support_count_test
}

main