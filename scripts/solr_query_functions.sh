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
    jq '[.response .docs[]? |
        { '"$2"'
        }]' |
    jq -r '(.[0] | keys_unsorted) as $keys |
            map([.[ $keys[] ]])[] |
            @tsv' >> "$3";
}

process_parameter()
{
    if [ "$#" -ne 5 ]; then
        error_exit "Usage: process_parameter solr_core_url query_string jq_filter_attributes documents_per_request output_filename.";
    fi
    
    core_url="$1"
    query="$2"
    jq_filter_attributes="$3"
    step="$4"
    output="$5"
    
    num=$(curl -sSLN "$core_url""$query"'&rows=0' | jq '.response.numFound')
    
    if [ "$num" != "" ]; then
    
      if [ "$num" -gt "$step" ]; then
    
          for i in $(seq 0 $step $num);
          do
              url="$core_url""$query"'&start='"$i"'&rows='"$step";
              fetch_data "$url" "$jq_filter_attributes" "$output";
              sleep 1;
          done
    
      else
          url="$core_url""$query"'&start=0&rows='"$step";
          fetch_data "$url" "$jq_filter_attributes" "$output";
      fi;
    
    
    else
      error_exit "Failed to obtain the number of documents from the Solr server";
    
    fi;
}



fetch_facet_pivot_data()
{
    if [ "$#" -ne 3 ]; then
        error_exit "Usage: fetch_facet_pivot_data url jq_filter_attributes output_filename";
    fi;
    
    core_url="$1"
    jq_filter_attributes="$2"
    output_file="$3"
    
    # Obtain the status code with the response
    # see : https://stackoverflow.com/questions/38906626/curl-to-return-http-status-code-along-with-the-response
    
    data=$(curl -sSLN -w "%{http_code}" "$core_url")
    check_http_status_code "$data"
    
    # Remove the 200 status code from the end of the response and process
    json=${data%200}
    
    printf '%s' $json | \
    jq '[.facet_counts .facet_pivot[]?[]? | '"$jq_filter_attributes"' ]' |
    jq -r '(.[0] | keys_unsorted) as $keys |
            map([.[ $keys[] ]])[] |
            @tsv' >> "$output_file";
}




process_facet_pivot_query()
{
    if [ "$#" -ne 4 ]; then
        error_exit "Usage: process_facet_pivot_query solr_core_url query_string jq_filter_attributes output_filename.";
    fi
    
    core_url="$1"
    query="$2"
    jq_filter_attributes="$3"
    output="$4"
    
    url="$core_url""$query";
    fetch_facet_pivot_data "$url" "$jq_filter_attributes" "$output";
}