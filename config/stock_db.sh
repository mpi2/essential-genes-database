#!/bin/bash
set -e

# see: https://docs.docker.com/samples/library/postgres/

# The initialization files in /docker-entrypoint-initdb.d will be executed in sorted name 
# order as defined by the current locale, which defaults to en_US.utf8. Hence the name 
# stock_db.sh to follow the sql file containing the schema.

# scripts in /docker-entrypoint-initdb.d are only run if you start the container with a 
# data directory that is empty; any pre-existing database will be left untouched on 
# container startup. One common problem is that if one of your /docker-entrypoint-initdb.d 
# scripts fails (which will cause the entrypoint script to exit) and your orchestrator 
# restarts the container with the already initialized data directory, it will not continue 
# on with your scripts.


# It is recommended that any psql commands that are run inside of a *.sh script be 
# executed as POSTGRES_USER by using the --username "$POSTGRES_USER" flag. This user will 
# be able to connect without a password due to the presence of trust authentication for 
# Unix socket connections made inside the container.


printf '#! /usr/bin/bash\nstart=%s\n' $(date +"%s") > /usr/local/data/postgres_processing_time.sh

# HGNC_data_load.txt

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy hgnc_gene (hgnc_acc_id,symbol,name,locus_group,locus_type,status,location,location_sortable,alias_symbol,alias_name,prev_symbol,prev_name,gene_family,gene_family_acc_id,date_approved_reserved,date_symbol_changed,date_name_changed,date_modified,entrez_acc_id,ensembl_gene_acc_id,vega_acc_id,ucsc_acc_id,ena,refseq_accession,ccds_acc_id,uniprot_acc_ids,pubmed_acc_id,mgi_gene_acc_id,rgd_acc_id,lsdb,cosmic,omim_acc_id,mirbase,homeodb,snornabase,bioparadigms_slc,orphanet,pseudogene_org,horde_acc_id,merops,imgt,iuphar,kznf_gene_catalog,mamit_trnadb,cd,lncrnadb,enzyme_acc_id,intermediate_filament_db,rna_central_acc_ids,lncipedia,gtrnadb,agr_acc_id) FROM '/mnt/non_alt_loci_set.txt' with (DELIMITER E'\t', NULL '', FORMAT CSV, header TRUE)"



psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy hgnc_gene (hgnc_acc_id,symbol,name,locus_group,locus_type,status,location,location_sortable,alias_symbol,alias_name,prev_symbol,prev_name,gene_family,gene_family_acc_id,date_approved_reserved,date_symbol_changed,date_name_changed,date_modified,entrez_acc_id,ensembl_gene_acc_id,vega_acc_id,ucsc_acc_id,ena,refseq_accession,ccds_acc_id,uniprot_acc_ids,pubmed_acc_id,mgi_gene_acc_id,rgd_acc_id,lsdb,cosmic,omim_acc_id,mirbase,homeodb,snornabase,bioparadigms_slc,orphanet,pseudogene_org,horde_acc_id,merops,imgt,iuphar,kznf_gene_catalog,mamit_trnadb,cd,lncrnadb,enzyme_acc_id,intermediate_filament_db,rna_central_acc_ids,lncipedia,gtrnadb,agr_acc_id) FROM '/mnt/alternative_loci_set.txt' with (DELIMITER E'\t', NULL '', FORMAT CSV, header TRUE)"


# HCOP_data_load.txt into a temporary table.


psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy hcop_tmp (human_entrez_gene_acc_id,human_ensembl_gene_acc_id,hgnc_acc_id,human_name,human_symbol,human_chr,human_assert_acc_ids,mouse_entrez_gene_acc_id,mouse_ensembl_gene_acc_id,mgi_gene_acc_id,mouse_name,mouse_symbol,mouse_chr,mouse_assert_acc_ids,support) FROM '/mnt/human_mouse_hcop_fifteen_column.txt' with (DELIMITER E'\t', NULL '-', FORMAT CSV, header TRUE)"


# MgiGene_data_load.txt

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy mgi_gene (mgi_gene_acc_id,type,symbol,name,genome_build,entrez_gene_acc_id,ncbi_chromosome,ncbi_start,ncbi_stop,ncbi_strand,ensembl_gene_acc_id,ensembl_chromosome,ensembl_start,ensembl_stop,ensembl_strand) FROM '/mnt/MGI_Gene_Model_Coord.rpt' with (DELIMITER E'\t', NULL 'null', FORMAT CSV, header TRUE)"


# MGI_Mrk_List2_data_load.txt

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy mgi_mrk_list2 (mgi_marker_acc_id,chr,cM,start,stop,strand,symbol,status,name,marker_type,feature_type,synonyms) FROM '/mnt/MRK_List2.rpt' with (DELIMITER E'\t', NULL '', FORMAT CSV, header TRUE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy mouse_gene_synonym (mgi_gene_acc_id,synonym) FROM '/mnt/Mrk_synonyms.txt' with (DELIMITER E'\t', NULL '', FORMAT CSV, header FALSE)"


psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy human_gene_synonym (hgnc_acc_id,synonym) FROM '/mnt/HGNC_synonyms.txt' with (DELIMITER E'\t', NULL '', FORMAT CSV, header FALSE)"

# Populate mouse gene with all the information in the MGI_Gene_Model_Coord.rpt
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO mouse_gene (symbol,name,mgi_gene_acc_id,type,genome_build,entrez_gene_acc_id,ncbi_chromosome,ncbi_start,ncbi_stop,ncbi_strand,ensembl_gene_acc_id,ensembl_chromosome,ensembl_start,ensembl_stop,ensembl_strand,subtype,mgi_cm,mgi_chromosome,mgi_strand,mgi_start,mgi_stop) 
SELECT mg.symbol,mg.name,mg.mgi_gene_acc_id,mg.type,mg.genome_build,mg.entrez_gene_acc_id,mg.ncbi_chromosome,mg.ncbi_start,mg.ncbi_stop,mg.ncbi_strand,mg.ensembl_gene_acc_id,mg.ensembl_chromosome,mg.ensembl_start,mg.ensembl_stop,mg.ensembl_strand, mrk.feature_type, btrim(mrk.cm), mrk.chr, mrk.strand, mrk.start, mrk.stop from mgi_gene mg
left outer join mgi_mrk_list2 mrk
ON mg.mgi_gene_acc_id = mrk.mgi_marker_acc_id"

# Add the MGI localised genes without NCBI or ENSEMBL coordinates 
# i.e. not present in MGI_Gene_Model_Coord.rpt, only found in the MRK_List2.rpt
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO mouse_gene (symbol,name,mgi_gene_acc_id,type,subtype,mgi_cm,mgi_chromosome,mgi_strand,mgi_start,mgi_stop) SELECT mrk2.symbol, mrk2.name, mrk2.mgi_marker_acc_id, mrk2.marker_type, mrk2.feature_type, btrim(mrk2.cm), mrk2.chr, mrk2.strand, mrk2.start, mrk2.stop FROM ( select * from mgi_mrk_list2 as mrk3 where mrk3.start is not null and mrk3.stop is not null and mrk3.marker_type = 'Gene' and mrk3.mgi_marker_acc_id not in (select mg2.mgi_gene_acc_id from mgi_gene as mg2)) as mrk2"

# Add MGI genes without localisation.
# This includes syntenic, classical genetic markers and unlocalised ESTs 
# (perhaps some of these are genes not present in the reference sequence).
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO mouse_gene (symbol,name,mgi_gene_acc_id,type,subtype, mgi_cm) SELECT mrk2.symbol, mrk2.name, mrk2.mgi_marker_acc_id, mrk2.marker_type, mrk2.feature_type, btrim(mrk2.cm)  FROM (select * from mgi_mrk_list2 as mrk where mrk.marker_type = 'Gene' and mrk.mgi_marker_acc_id not in (select mgi_gene_acc_id from mgi_gene) and mrk.id not in ( select mrk4.id from mgi_mrk_list2 as mrk4 where mrk4.start is not null and mrk4.stop is not null and mrk4.marker_type = 'Gene'  and mrk4.mgi_marker_acc_id not in (select mg4.mgi_gene_acc_id from mgi_gene mg4))) as mrk2"

# Add MGI QTLs with and without localisation. MGI manages their nomenclature
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO mouse_gene (symbol,name,mgi_gene_acc_id,type,subtype,mgi_cm,mgi_chromosome,mgi_strand,mgi_start,mgi_stop) SELECT  mrk.symbol, mrk.name, mrk.mgi_marker_acc_id, mrk.marker_type, mrk.feature_type, btrim(mrk.cm), mrk.chr, mrk.strand, mrk.start, mrk.stop from mgi_mrk_list2 as mrk where mrk.marker_type = 'QTL';"


psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table mgi_gene"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table mgi_mrk_list2"


psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO mouse_gene_synonym_relation (mouse_gene_id, mouse_gene_synonym_id) 
SELECT mouse_gene.id, mouse_gene_synonym.id
FROM  mouse_gene, mouse_gene_synonym
WHERE mouse_gene.mgi_gene_acc_id = mouse_gene_synonym.mgi_gene_acc_id"




psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO human_gene (symbol,name,hgnc_acc_id,ensembl_gene_acc_id,entrez_gene_acc_id) 
SELECT symbol,name,hgnc_acc_id,id,ensembl_gene_acc_id,entrez_acc_id from hgnc_gene where locus_type != 'readthrough'"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "UPDATE hgnc_gene SET human_gene_id = (select h.id from human_gene h where h.hgnc_acc_id=hgnc_gene.hgnc_acc_id)"


psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO human_gene_synonym_relation (human_gene_id, human_gene_synonym_id) 
SELECT human_gene.id, human_gene_synonym.id
FROM  human_gene, human_gene_synonym
WHERE human_gene.hgnc_acc_id = human_gene_synonym.hgnc_acc_id"



# Create the final version of HCOP
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO hcop (mouse_gene_id, human_gene_id,human_entrez_gene_acc_id,human_ensembl_gene_acc_id,hgnc_acc_id,human_name,human_symbol,human_chr,human_assert_acc_ids,mouse_entrez_gene_acc_id,mouse_ensembl_gene_acc_id,mgi_gene_acc_id,mouse_name,mouse_symbol,mouse_chr,mouse_assert_acc_ids,support)
select a.mouse_gene_id, human_gene.id as \"human_gene_id\", a.human_entrez_gene_acc_id,a.human_ensembl_gene_acc_id,a.hgnc_acc_id,a.human_name,a.human_symbol,a.human_chr,a.human_assert_acc_ids,a.mouse_entrez_gene_acc_id,a.mouse_ensembl_gene_acc_id,a.mgi_gene_acc_id,a.mouse_name,a.mouse_symbol,a.mouse_chr,a.mouse_assert_acc_ids,a.support from (select mouse_gene.id as \"mouse_gene_id\", h.human_entrez_gene_acc_id,h.human_ensembl_gene_acc_id,h.hgnc_acc_id,h.human_name,h.human_symbol,h.human_chr,h.human_assert_acc_ids,h.mouse_entrez_gene_acc_id,h.mouse_ensembl_gene_acc_id,h.mgi_gene_acc_id,h.mouse_name,h.mouse_symbol,h.mouse_chr,h.mouse_assert_acc_ids,h.support from hcop_tmp h left outer join mouse_gene ON h.mgi_gene_acc_id=mouse_gene.mgi_gene_acc_id) as a left outer join human_gene ON a.hgnc_acc_id=human_gene.hgnc_acc_id"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP TABLE hcop_tmp"



psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO ortholog (support, support_count,human_gene_id,mouse_gene_id)
select array_to_string(array( select distinct unnest(string_to_array(support, ','))),',') as list, array_length(array( select distinct unnest(string_to_array(support, ','))),1) as count, human_gene.id, mouse_gene.id from hcop h, human_gene, mouse_gene 
WHERE h.hgnc_acc_id = human_gene.hgnc_acc_id and 
h.mgi_gene_acc_id = mouse_gene.mgi_gene_acc_id
GROUP BY list,count,human_gene.id, mouse_gene.id
order by count desc"

# IDG data 
# Load the original IDG data into a temporary table.
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy idg_tmp (name, tdl, symbol, uniprot_acc_id, chr) FROM '/mnt/idg_out.txt' with (DELIMITER E'\t', FORMAT CSV, header TRUE)"

# Construct the final table - match on Uniprot IDs
#
# Initial step based on exact match of Uniprot ID, assuming that only one ID is stored in the HGNC Uniprot_acc_ids field.
# This migrates most of the data.
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO idg (human_gene_id, name, tdl, symbol, uniprot_acc_id, chr) select h.id, i.name,i.tdl, i.symbol, i.uniprot_acc_id, i.chr from idg_tmp i, hgnc_gene g, human_gene h where i.uniprot_acc_id=g.uniprot_acc_ids and g.human_gene_id = h.id"

# Second step to load the remaining data
# (Note: The hgnc gene table contains an array of uniprot ids hence matching is based on array 'is contained by' function)
# This is an expensive operation if carried out for all entries in idg_tmp takes several minutes to complete.
# It is used here to finish migration of the data for cases where the HGNC entry has multiple 
# Uniprot IDs separated by a '|' character.
#
# This approach misses one entry 'EPPIN-WFDC6 readthrough', which is a hybrid with references for two Uniprot ids that
# also correspond to separate entries for EPPIN and WFDC6 that are already in the system. 
# Running the array comparison method over all the data will load this entry.
# 
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO idg (human_gene_id, name, tdl, symbol, uniprot_acc_id, chr) select h.id, i.name,i.tdl, i.symbol, i.uniprot_acc_id, i.chr from ( select * from idg_tmp where uniprot_acc_id not in (select uniprot_acc_id from idg) ) as i, hgnc_gene g, human_gene h where string_to_array(i.uniprot_acc_id, '') <@ string_to_array(g.uniprot_acc_ids,'|') and g.human_gene_id = h.id"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table idg_tmp"



# ClinGen data
# The first 6 lines of the file describe the contents of the file, so need to be removed. 
tail -n +7 /mnt/gene-dosage.csv | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy clingen_tmp (symbol, hgnc_acc_id, haploinsufficiency, triplosensitivity, report, date) FROM STDIN with (DELIMITER E',', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO clingen (human_gene_id, haploinsufficiency, triplosensitivity, report, date) 
select h.id, t.haploinsufficiency, t.triplosensitivity, t.report, t.date from human_gene h, clingen_tmp t where h.hgnc_acc_id = t.hgnc_acc_id"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table clingen_tmp"




# DepMap Achilles gene effect data
# Load the names of the cell types
head -n 1 /mnt/achilles_gene_effect.col.formatted.tsv | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy achillies_cell_types (cell_type_names) FROM STDIN with (DELIMITER E'|', FORMAT CSV, header FALSE)"

# Load the raw gene effect data
tail -n +2 /mnt/achilles_gene_effect.col.formatted.tsv | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy achilles_gene_effect_raw (symbol, entrez_acc_id, cell_type_data) FROM STDIN with (DELIMITER E'|', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "update achilles_gene_effect_raw set cell_type_name_id = (select id from achillies_cell_types)"

# Generate the table with the mean gene effect
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO achilles_gene_effect (human_gene_id, raw_data_id, entrez_acc_id, mean_gene_effect) 
select h.id, a.id, a.entrez_acc_id, (select avg(unnest) from unnest(string_to_array(a.cell_type_data, E'\t','')::float[])) from human_gene h, achilles_gene_effect_raw a where a.entrez_acc_id = h.entrez_gene_acc_id"




# IMPC embryo viability data
# Load
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_embryo_viability_tmp (parameter_stable_id, project_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center_id, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) FROM '/mnt/embryo_viability.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_embryo_viability (mouse_gene_id, parameter_stable_id, project_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center_id, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center_id, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_embryo_viability_tmp t where m.mgi_gene_acc_id = t.gene_accession_id"

# load additional data where synonyms can be resolved
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_embryo_viability (mouse_gene_id, parameter_stable_id, project_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center_id, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center_id, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_embryo_viability_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.gene_symbol from impc_embryo_viability_tmp tt where tt.gene_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.gene_symbol =renamed.synonym"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_embryo_viability_tmp"


# IMPC adult viability data
# Load
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_adult_viability_tmp (parameter_stable_id, project_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center_id, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) FROM '/mnt/adult_viability.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_adult_viability (mouse_gene_id, parameter_stable_id, project_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center_id, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center_id, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_adult_viability_tmp t where m.mgi_gene_acc_id = t.gene_accession_id"

# load additional data where synonyms can be resolved
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_adult_viability (mouse_gene_id, parameter_stable_id, project_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center_id, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center_id, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_adult_viability_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.gene_symbol from impc_adult_viability_tmp tt where tt.gene_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.gene_symbol =renamed.synonym"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_adult_viability_tmp"





# IMPC phenotype data
# Load
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_significant_phenotype_tmp (ontology_db_id, assertion_type, assertion_type_id, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, intermediate_mp_term_ids, intermediate_mp_term_names, impc_marker_symbol, impc_marker_accession_id, colony_id, impc_allele_name, impc_allele_symbol, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, phenotyping_center, project_name, project_fullname, resource_name, resource_fullname, sex, zygosity, pipeline_name, pipeline_stable_id, pipeline_stable_key, procedure_name, procedure_stable_id, procedure_stable_key, parameter_name, parameter_stable_id, parameter_stable_key, statistical_method, p_value, effect_size, life_stage_acc, life_stage_name) FROM '/mnt/impc_phenotype_data.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_significant_phenotype (mouse_gene_id, ontology_db_id, assertion_type, assertion_type_id, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, intermediate_mp_term_ids, intermediate_mp_term_names, impc_marker_symbol, impc_marker_accession_id, colony_id, impc_allele_name, impc_allele_symbol, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, phenotyping_center, project_name, project_fullname, resource_name, resource_fullname, sex, zygosity, pipeline_name, pipeline_stable_id, pipeline_stable_key, procedure_name, procedure_stable_id, procedure_stable_key, parameter_name, parameter_stable_id, parameter_stable_key, statistical_method, p_value, effect_size, life_stage_acc, life_stage_name) select m.id, t.ontology_db_id, t.assertion_type, t.assertion_type_id, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.intermediate_mp_term_ids, t.intermediate_mp_term_names, t.impc_marker_symbol, t.impc_marker_accession_id, t.colony_id, t.impc_allele_name, t.impc_allele_symbol, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.phenotyping_center, t.project_name, t.project_fullname, t.resource_name, t.resource_fullname, t.sex, t.zygosity, t.pipeline_name, t.pipeline_stable_id, t.pipeline_stable_key, t.procedure_name, t.procedure_stable_id, t.procedure_stable_key, t.parameter_name, t.parameter_stable_id, t.parameter_stable_key, t.statistical_method, t.p_value, t.effect_size, t.life_stage_acc, t.life_stage_name from mouse_gene m, impc_significant_phenotype_tmp t where m.mgi_gene_acc_id = t.impc_marker_accession_id"

# load additional data where synonyms can be resolved
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_significant_phenotype (mouse_gene_id, ontology_db_id, assertion_type, assertion_type_id, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, intermediate_mp_term_ids, intermediate_mp_term_names, impc_marker_symbol, impc_marker_accession_id, colony_id, impc_allele_name, impc_allele_symbol, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, phenotyping_center, project_name, project_fullname, resource_name, resource_fullname, sex, zygosity, pipeline_name, pipeline_stable_id, pipeline_stable_key, procedure_name, procedure_stable_id, procedure_stable_key, parameter_name, parameter_stable_id, parameter_stable_key, statistical_method, p_value, effect_size, life_stage_acc, life_stage_name) select m.id, t.ontology_db_id, t.assertion_type, t.assertion_type_id, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.intermediate_mp_term_ids, t.intermediate_mp_term_names, t.impc_marker_symbol, t.impc_marker_accession_id, t.colony_id, t.impc_allele_name, t.impc_allele_symbol, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.phenotyping_center, t.project_name, t.project_fullname, t.resource_name, t.resource_fullname, t.sex, t.zygosity, t.pipeline_name, t.pipeline_stable_id, t.pipeline_stable_key, t.procedure_name, t.procedure_stable_id, t.procedure_stable_key, t.parameter_name, t.parameter_stable_id, t.parameter_stable_key, t.statistical_method, t.p_value, t.effect_size, t.life_stage_acc, t.life_stage_name from mouse_gene m, impc_significant_phenotype_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.impc_marker_symbol from impc_significant_phenotype_tmp tt where tt.impc_marker_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.impc_marker_symbol =renamed.synonym"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_significant_phenotype_tmp"






# IMPC proceedure data
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_proceedure_count (phenotyping_center, procedure_stable_id, count) FROM '/mnt/impc_proceedures_by_centre.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"







# IMPC stats data
# Load the data
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_statistical_result_tmp (doc_id, db_id, data_type, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, life_stage_acc, life_stage_name, project_name, phenotyping_center, pipeline_stable_id, pipeline_stable_key, pipeline_name, pipeline_id, procedure_stable_id, procedure_stable_key, procedure_name, procedure_id, parameter_stable_id, parameter_stable_key, parameter_name, parameter_id, colony_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_name, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, genetic_background, zygosity, status, p_value, significant) FROM '/mnt/impc_stats_data.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_statistical_result (mouse_gene_id, doc_id, db_id, data_type, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, life_stage_acc, life_stage_name, project_name, phenotyping_center, pipeline_stable_id, pipeline_stable_key, pipeline_name, pipeline_id, procedure_stable_id, procedure_stable_key, procedure_name, procedure_id, parameter_stable_id, parameter_stable_key, parameter_name, parameter_id, colony_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_name, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, genetic_background, zygosity, status, p_value, significant) select m.id, t.doc_id, t.db_id, t.data_type, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.life_stage_acc, t.life_stage_name, t.project_name, t.phenotyping_center, t.pipeline_stable_id, t.pipeline_stable_key, t.pipeline_name, t.pipeline_id, t.procedure_stable_id, t.procedure_stable_key, t.procedure_name, t.procedure_id, t.parameter_stable_id, t.parameter_stable_key, t.parameter_name, t.parameter_id, t.colony_id, t.impc_marker_symbol, t.impc_marker_accession_id, t.impc_allele_symbol, t.impc_allele_name, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.genetic_background, t.zygosity, t.status, t.p_value, t.significant from mouse_gene m, impc_statistical_result_tmp t where m.mgi_gene_acc_id = t.impc_marker_accession_id"

# load additional data where synonyms can be resolved
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_statistical_result (mouse_gene_id, doc_id, db_id, data_type, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, life_stage_acc, life_stage_name, project_name, phenotyping_center, pipeline_stable_id, pipeline_stable_key, pipeline_name, pipeline_id, procedure_stable_id, procedure_stable_key, procedure_name, procedure_id, parameter_stable_id, parameter_stable_key, parameter_name, parameter_id, colony_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_name, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, genetic_background, zygosity, status, p_value, significant) select m.id, t.doc_id, t.db_id, t.data_type, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.life_stage_acc, t.life_stage_name, t.project_name, t.phenotyping_center, t.pipeline_stable_id, t.pipeline_stable_key, t.pipeline_name, t.pipeline_id, t.procedure_stable_id, t.procedure_stable_key, t.procedure_name, t.procedure_id, t.parameter_stable_id, t.parameter_stable_key, t.parameter_name, t.parameter_id, t.colony_id, t.impc_marker_symbol, t.impc_marker_accession_id, t.impc_allele_symbol, t.impc_allele_name, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.genetic_background, t.zygosity, t.status, t.p_value, t.significant from mouse_gene m, impc_statistical_result_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.impc_marker_symbol from impc_statistical_result_tmp tt where tt.impc_marker_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.impc_marker_symbol =renamed.synonym"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_statistical_result_tmp"


printf 'end=%s\n' $(date +"%s") >> /usr/local/data/postgres_processing_time.sh
printf "echo -n 'Postgresql processing time: '\n" >> /usr/local/data/postgres_processing_time.sh
echo 'printf "'"%d s\n"'" $(( $end - $start ))'   >> /usr/local/data/postgres_processing_time.sh
chmod 755 /usr/local/data/postgres_processing_time.sh