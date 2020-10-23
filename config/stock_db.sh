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


psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /mnt/orthologydb_schema.sql

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /mnt/essential_genes_schema_additions.sql

# Load the orthology data
for i in ortholog hgnc_gene mouse_gene mouse_gene_synonym mouse_gene_synonym_relation mouse_mapping_filter human_gene human_mapping_filter human_gene_synonym human_gene_synonym_relation; do
	psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /mnt/orthologydb_"$i".sql
done;

# IDG data 
# Load the original IDG data into a temporary table.
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy idg_tmp (name, tdl, family, symbol, uniprot_acc_id, chr) FROM '/mnt/idg_out.txt' with (DELIMITER E'\t', FORMAT CSV, header TRUE)"

# Construct the final table - match on Uniprot IDs
#
# Initial step based on exact match of Uniprot ID, assuming that only one ID is stored in the HGNC Uniprot_acc_ids field.
# This migrates most of the data.
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO idg (human_gene_id, name, tdl, family, symbol, uniprot_acc_id, chr) select h.id, i.name,i.tdl, i.family, i.symbol, i.uniprot_acc_id, i.chr from idg_tmp i, hgnc_gene g, human_gene h where i.uniprot_acc_id=g.uniprot_acc_ids and g.human_gene_id = h.id"

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
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO idg (human_gene_id, name, tdl, family, symbol, uniprot_acc_id, chr) select h.id, i.name,i.tdl, i.family, i.symbol, i.uniprot_acc_id, i.chr from ( select * from idg_tmp where uniprot_acc_id not in (select uniprot_acc_id from idg) ) as i, hgnc_gene g, human_gene h where string_to_array(i.uniprot_acc_id, '') <@ string_to_array(g.uniprot_acc_ids,'|') and g.human_gene_id = h.id"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table idg_tmp"



# ClinGen data
# The first 6 lines of the file describe the contents of the file, so need to be removed. 
tail -n +7 /mnt/gene-dosage.csv | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy clingen_tmp (symbol, hgnc_acc_id, haploinsufficiency, triplosensitivity, report, date) FROM STDIN with (DELIMITER E',', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO clingen (human_gene_id, haploinsufficiency, triplosensitivity, report, date) 
select h.id, t.haploinsufficiency, t.triplosensitivity, t.report, t.date from human_gene h, clingen_tmp t where h.hgnc_acc_id = t.hgnc_acc_id"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table clingen_tmp"



# GnomAD data
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy gnomad_plof_tmp (gene_symbol, transcript, obs_mis, exp_mis, oe_mis, mu_mis, possible_mis, obs_mis_pphen, exp_mis_pphen, oe_mis_pphen, possible_mis_pphen, obs_syn, exp_syn, oe_syn, mu_syn, possible_syn, obs_lof, mu_lof, possible_lof, exp_lof, pLI, pNull, pRec, oe_lof, oe_syn_lower, oe_syn_upper, oe_mis_lower, oe_mis_upper, oe_lof_lower, oe_lof_upper, constraint_flag, syn_z, mis_z, lof_z, oe_lof_upper_rank, oe_lof_upper_bin, oe_lof_upper_bin_6, n_sites, classic_caf, max_af, no_lofs, obs_het_lof, obs_hom_lof, defined, p, exp_hom_lof, classic_caf_afr, classic_caf_amr, classic_caf_asj, classic_caf_eas, classic_caf_fin, classic_caf_nfe, classic_caf_oth, classic_caf_sas, p_afr, p_amr, p_asj, p_eas, p_fin, p_nfe, p_oth, p_sas, transcript_type, gene_id, transcript_level, cds_length, num_coding_exons, gene_type, gene_length, exac_pLI, exac_obs_lof, exac_exp_lof, exac_oe_lof, brain_expression, chromosome, start_position, end_position) FROM '/mnt/gnomad.lof_metrics.by_gene.txt' with (DELIMITER E'\t', FORMAT CSV, header TRUE, NULL 'NA')"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO gnomad_plof (human_gene_id, gene_symbol, transcript, obs_mis, exp_mis, oe_mis, mu_mis, possible_mis, obs_mis_pphen, exp_mis_pphen, oe_mis_pphen, possible_mis_pphen, obs_syn, exp_syn, oe_syn, mu_syn, possible_syn, obs_lof, mu_lof, possible_lof, exp_lof, pLI, pNull, pRec, oe_lof, oe_syn_lower, oe_syn_upper, oe_mis_lower, oe_mis_upper, oe_lof_lower, oe_lof_upper, constraint_flag, syn_z, mis_z, lof_z, oe_lof_upper_rank, oe_lof_upper_bin, oe_lof_upper_bin_6, n_sites, classic_caf, max_af, no_lofs, obs_het_lof, obs_hom_lof, defined, p, exp_hom_lof, classic_caf_afr, classic_caf_amr, classic_caf_asj, classic_caf_eas, classic_caf_fin, classic_caf_nfe, classic_caf_oth, classic_caf_sas, p_afr, p_amr, p_asj, p_eas, p_fin, p_nfe, p_oth, p_sas, transcript_type, gene_id, transcript_level, cds_length, num_coding_exons, gene_type, gene_length, exac_pLI, exac_obs_lof, exac_exp_lof, exac_oe_lof, brain_expression, chromosome, start_position, end_position) 
select h.id, t.gene_symbol, t.transcript, t.obs_mis, t.exp_mis, t.oe_mis, t.mu_mis, t.possible_mis, t.obs_mis_pphen, t.exp_mis_pphen, t.oe_mis_pphen, t.possible_mis_pphen, t.obs_syn, t.exp_syn, t.oe_syn, t.mu_syn, t.possible_syn, t.obs_lof, t.mu_lof, t.possible_lof, t.exp_lof, t.pLI, t.pNull, t.pRec, t.oe_lof, t.oe_syn_lower, t.oe_syn_upper, t.oe_mis_lower, t.oe_mis_upper, t.oe_lof_lower, t.oe_lof_upper, t.constraint_flag, t.syn_z, t.mis_z, t.lof_z, t.oe_lof_upper_rank, t.oe_lof_upper_bin, t.oe_lof_upper_bin_6, t.n_sites, t.classic_caf, t.max_af, t.no_lofs, t.obs_het_lof, t.obs_hom_lof, t.defined, t.p, t.exp_hom_lof, t.classic_caf_afr, t.classic_caf_amr, t.classic_caf_asj, t.classic_caf_eas, t.classic_caf_fin, t.classic_caf_nfe, t.classic_caf_oth, t.classic_caf_sas, t.p_afr, t.p_amr, t.p_asj, t.p_eas, t.p_fin, t.p_nfe, t.p_oth, t.p_sas, t.transcript_type, t.gene_id, t.transcript_level, t.cds_length, t.num_coding_exons, t.gene_type, t.gene_length, t.exac_pLI, t.exac_obs_lof, t.exac_exp_lof, t.exac_oe_lof, t.brain_expression, t.chromosome, t.start_position, t.end_position from human_gene h, gnomad_plof_tmp t where h.ensembl_gene_acc_id = t.gene_id"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table gnomad_plof_tmp"



# DepMap Achilles gene effect data
# Load the names of the cell types
head -n 1 /mnt/achilles_gene_effect.col.formatted.tsv | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy achillies_cell_types (cell_type_names) FROM STDIN with (DELIMITER E'|', FORMAT CSV, header FALSE)"

# Load the raw gene effect data
tail -n +2 /mnt/achilles_gene_effect.col.formatted.tsv | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy achilles_gene_effect_raw (symbol, entrez_acc_id, cell_type_data) FROM STDIN with (DELIMITER E'|', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "update achilles_gene_effect_raw set cell_type_name_id = (select id from achillies_cell_types)"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "vacuum full achilles_gene_effect_raw"

# Generate the table with the mean gene effect
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO achilles_gene_effect (human_gene_id, raw_data_id, entrez_acc_id, mean_gene_effect) 
select h.id, a.id, a.entrez_acc_id, (select avg(unnest) from unnest(string_to_array(a.cell_type_data, E'\t','')::float[])) from human_gene h, achilles_gene_effect_raw a where a.entrez_acc_id = h.entrez_gene_acc_id"




# IMPC embryo viability data
# Load
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_embryo_viability_tmp (parameter_stable_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) FROM '/mnt/embryo_viability.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_embryo_viability (mouse_gene_id, parameter_stable_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_embryo_viability_tmp t where m.mgi_gene_acc_id = t.gene_accession_id"

# load additional data where synonyms can be resolved
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_embryo_viability (mouse_gene_id, parameter_stable_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_embryo_viability_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.gene_symbol from impc_embryo_viability_tmp tt where tt.gene_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.gene_symbol =renamed.synonym"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_embryo_viability_tmp"


# IMPC adult viability data
# Load
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_adult_viability_tmp (parameter_stable_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) FROM '/mnt/adult_viability.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_adult_viability (mouse_gene_id, parameter_stable_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_adult_viability_tmp t where m.mgi_gene_acc_id = t.gene_accession_id"

# load additional data where synonyms can be resolved
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_adult_viability (mouse_gene_id, parameter_stable_id, project_name, procedure_group, procedure_stable_id, pipeline_stable_id, pipeline_name, phenotyping_center, developmental_stage_acc, developmental_stage_name, gene_symbol, gene_accession_id, colony_id, biological_sample_group, experiment_source_id, allele_accession_id, allele_symbol, allelic_composition, genetic_background, strain_accession_id, strain_name, zygosity, sex, category, parameter_name, procedure_name) select m.id, t.parameter_stable_id, t.project_name, t.procedure_group, t.procedure_stable_id, t.pipeline_stable_id, t.pipeline_name, t.phenotyping_center, t.developmental_stage_acc, t.developmental_stage_name, t.gene_symbol, t.gene_accession_id, t.colony_id, t.biological_sample_group, t.experiment_source_id, t.allele_accession_id, t.allele_symbol, t.allelic_composition, t.genetic_background, t.strain_accession_id, t.strain_name, t.zygosity, t.sex, t.category, t.parameter_name, t.procedure_name from mouse_gene m, impc_adult_viability_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.gene_symbol from impc_adult_viability_tmp tt where tt.gene_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.gene_symbol =renamed.synonym"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_adult_viability_tmp"





# IMPC phenotype data
# Load
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_significant_phenotype_tmp (assertion_type, assertion_type_id, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, intermediate_mp_term_ids, intermediate_mp_term_names, impc_marker_symbol, impc_marker_accession_id, colony_id, impc_allele_name, impc_allele_symbol, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, phenotyping_center, project_name, resource_name, sex, zygosity, pipeline_name, pipeline_stable_id, procedure_name, procedure_stable_id, parameter_name, parameter_stable_id, statistical_method, p_value, effect_size, life_stage_acc, life_stage_name) FROM '/mnt/impc_phenotype_data.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_significant_phenotype (mouse_gene_id, assertion_type, assertion_type_id, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, intermediate_mp_term_ids, intermediate_mp_term_names, impc_marker_symbol, impc_marker_accession_id, colony_id, impc_allele_name, impc_allele_symbol, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, phenotyping_center, project_name, resource_name, sex, zygosity, pipeline_name, pipeline_stable_id, procedure_name, procedure_stable_id, parameter_name, parameter_stable_id, statistical_method, p_value, effect_size, life_stage_acc, life_stage_name) select m.id, t.assertion_type, t.assertion_type_id, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.intermediate_mp_term_ids, t.intermediate_mp_term_names, t.impc_marker_symbol, t.impc_marker_accession_id, t.colony_id, t.impc_allele_name, t.impc_allele_symbol, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.phenotyping_center, t.project_name, t.resource_name, t.sex, t.zygosity, t.pipeline_name, t.pipeline_stable_id, t.procedure_name, t.procedure_stable_id, t.parameter_name, t.parameter_stable_id, t.statistical_method, t.p_value, t.effect_size, t.life_stage_acc, t.life_stage_name from mouse_gene m, impc_significant_phenotype_tmp t where m.mgi_gene_acc_id = t.impc_marker_accession_id"

# load additional data where synonyms can be resolved
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_significant_phenotype (mouse_gene_id, assertion_type, assertion_type_id, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, intermediate_mp_term_ids, intermediate_mp_term_names, impc_marker_symbol, impc_marker_accession_id, colony_id, impc_allele_name, impc_allele_symbol, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, phenotyping_center, project_name, resource_name, sex, zygosity, pipeline_name, pipeline_stable_id, procedure_name, procedure_stable_id, parameter_name, parameter_stable_id, statistical_method, p_value, effect_size, life_stage_acc, life_stage_name) select m.id, t.assertion_type, t.assertion_type_id, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.intermediate_mp_term_ids, t.intermediate_mp_term_names, t.impc_marker_symbol, t.impc_marker_accession_id, t.colony_id, t.impc_allele_name, t.impc_allele_symbol, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.phenotyping_center, t.project_name, t.resource_name, t.sex, t.zygosity, t.pipeline_name, t.pipeline_stable_id, t.procedure_name, t.procedure_stable_id, t.parameter_name, t.parameter_stable_id, t.statistical_method, t.p_value, t.effect_size, t.life_stage_acc, t.life_stage_name from mouse_gene m, impc_significant_phenotype_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.impc_marker_symbol from impc_significant_phenotype_tmp tt where tt.impc_marker_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.impc_marker_symbol =renamed.synonym"

# drop the temporary table
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_significant_phenotype_tmp"








# IMPC stats data
# Load the data
# This approach required too much memory during the docker load and failed to run to completion
# - Instead just load the data through the copy command directly into the impc_statistical_result table since that operation was successful
# - the mouse_gene_id field has been removed from the impc_statistical_result table.
#
# psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_statistical_result_tmp (doc_id, db_id, data_type, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, life_stage_acc, life_stage_name, project_name, phenotyping_center, pipeline_stable_id, pipeline_stable_key, pipeline_name, pipeline_id, procedure_stable_id, procedure_stable_key, procedure_name, procedure_id, parameter_stable_id, parameter_stable_key, parameter_name, parameter_id, colony_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_name, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, genetic_background, zygosity, status, p_value, significant) FROM '/mnt/impc_stats_data.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"

# psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_statistical_result (mouse_gene_id, doc_id, db_id, data_type, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, life_stage_acc, life_stage_name, project_name, phenotyping_center, pipeline_stable_id, pipeline_stable_key, pipeline_name, pipeline_id, procedure_stable_id, procedure_stable_key, procedure_name, procedure_id, parameter_stable_id, parameter_stable_key, parameter_name, parameter_id, colony_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_name, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, genetic_background, zygosity, status, p_value, significant) select m.id, t.doc_id, t.db_id, t.data_type, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.life_stage_acc, t.life_stage_name, t.project_name, t.phenotyping_center, t.pipeline_stable_id, t.pipeline_stable_key, t.pipeline_name, t.pipeline_id, t.procedure_stable_id, t.procedure_stable_key, t.procedure_name, t.procedure_id, t.parameter_stable_id, t.parameter_stable_key, t.parameter_name, t.parameter_id, t.colony_id, t.impc_marker_symbol, t.impc_marker_accession_id, t.impc_allele_symbol, t.impc_allele_name, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.genetic_background, t.zygosity, t.status, t.p_value, t.significant from mouse_gene m, impc_statistical_result_tmp t where m.mgi_gene_acc_id = t.impc_marker_accession_id"

# load additional data where synonyms can be resolved
# psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_statistical_result (mouse_gene_id, doc_id, db_id, data_type, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, life_stage_acc, life_stage_name, project_name, phenotyping_center, pipeline_stable_id, pipeline_stable_key, pipeline_name, pipeline_id, procedure_stable_id, procedure_stable_key, procedure_name, procedure_id, parameter_stable_id, parameter_stable_key, parameter_name, parameter_id, colony_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_name, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, genetic_background, zygosity, status, p_value, significant) select m.id, t.doc_id, t.db_id, t.data_type, t.mp_term_id, t.mp_term_name, t.top_level_mp_term_ids, t.top_level_mp_term_names, t.life_stage_acc, t.life_stage_name, t.project_name, t.phenotyping_center, t.pipeline_stable_id, t.pipeline_stable_key, t.pipeline_name, t.pipeline_id, t.procedure_stable_id, t.procedure_stable_key, t.procedure_name, t.procedure_id, t.parameter_stable_id, t.parameter_stable_key, t.parameter_name, t.parameter_id, t.colony_id, t.impc_marker_symbol, t.impc_marker_accession_id, t.impc_allele_symbol, t.impc_allele_name, t.impc_allele_accession_id, t.impc_strain_name, t.impc_strain_accession_id, t.genetic_background, t.zygosity, t.status, t.p_value, t.significant from mouse_gene m, impc_statistical_result_tmp t, (select mgi_gene_acc_id, synonym from mouse_gene_synonym where synonym in ( select tt.impc_marker_symbol from impc_statistical_result_tmp tt where tt.impc_marker_accession_id not in (select m2.mgi_gene_acc_id from mouse_gene m2))) as renamed where m.mgi_gene_acc_id = renamed.mgi_gene_acc_id and t.impc_marker_symbol =renamed.synonym"

# drop the temporary table
# psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP table impc_statistical_result_tmp"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\copy impc_statistical_result (doc_id, data_type, mp_term_id, mp_term_name, top_level_mp_term_ids, top_level_mp_term_names, life_stage_acc, life_stage_name, project_name, phenotyping_center, pipeline_stable_id, pipeline_name, procedure_stable_id, procedure_name, parameter_stable_id, parameter_name, colony_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_name, impc_allele_accession_id, impc_strain_name, impc_strain_accession_id, genetic_background, zygosity, status, p_value, significant) FROM '/mnt/impc_stats_data.tsv' with (DELIMITER E'\t', FORMAT CSV, header FALSE)"




# Populate the table impc_count
#
# Preparation of the impc_count table is based on the max possible number of fusil bin scores without taking into account the ortholog data
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO impc_count (mouse_gene_id, impc_marker_symbol, impc_marker_accession_id, impc_allele_symbol, impc_allele_accession_id)
select mm.id, vv.gene_symbol, vv.gene_accession_id, vv.allele_symbol, vv.allele_accession_id from mouse_gene mm, impc_adult_viability vv where mm.mgi_gene_acc_id in ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1)) and mm.id = vv.mouse_gene_id group by mm.id, vv.gene_symbol, vv.gene_accession_id, vv.allele_symbol, vv.allele_accession_id"

# Enter the procedure count data
# Note the revised query within the inner join handles cases
# where there are multiple procedure_stable_id for a single Solr record
# In the output file after the JSON transformation these would be concatenated.
# For example as IMPC_ABR_002|IMPC_FER_001
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "UPDATE impc_count
SET significant_procedure_count = t2.count,
    significant_procedure_list = t2.significant_procedure_list
FROM impc_count t1
INNER JOIN (WITH sig_procedures_by_impc_allele_accession AS (select impc_allele_accession_id, unnest(string_to_array(procedure_stable_id,'|')) as procedure_stable_id
   from impc_significant_phenotype
   group by impc_allele_accession_id, procedure_stable_id)
select spl.impc_allele_accession_id,  count(distinct(spl.procedure_stable_id)) as count,  array_to_string(array_agg(distinct(spl.procedure_stable_id)),'|') as significant_procedure_list from sig_procedures_by_impc_allele_accession spl group by spl.impc_allele_accession_id) as t2
on t2.impc_allele_accession_id = t1.impc_allele_accession_id
WHERE
impc_count.impc_allele_accession_id = t2.impc_allele_accession_id"

# Note the revised query within the inner join handles cases
# where there are multiple procedure_stable_id for a single Solr record
# In the output file after the JSON transformation these would be concatenated.
# For example as IMPC_ABR_002|IMPC_FER_001
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "UPDATE impc_count
SET homozygous_significant_procedure_count = t2.count,
    homozygous_significant_procedure_list = t2.homozygous_significant_procedure_list
FROM impc_count t1
INNER JOIN (WITH 
hom_sig_procedures_by_impc_allele_accession AS (select impc_allele_accession_id, unnest(string_to_array(procedure_stable_id,'|')) as procedure_stable_id
   from impc_significant_phenotype
   where zygosity='homozygote'
   group by impc_allele_accession_id, procedure_stable_id)
select hspl.impc_allele_accession_id, count(distinct(hspl.procedure_stable_id)) as count, 
   array_to_string(array_agg(distinct(hspl.procedure_stable_id)),'|') as homozygous_significant_procedure_list
from 
hom_sig_procedures_by_impc_allele_accession hspl 
group by 
hspl.impc_allele_accession_id) as t2
on t2.impc_allele_accession_id = t1.impc_allele_accession_id
WHERE
impc_count.impc_allele_accession_id = t2.impc_allele_accession_id"

# Note the revised query within the inner join handles cases
# where there are multiple procedure_stable_id for a single Solr record
# In the output file after the JSON transformation these would be concatenated.
# For example as IMPC_ABR_002|IMPC_FER_001
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "UPDATE impc_count
SET total_successful_procedure_count = t2.count,
    total_successful_procedure_list = t2.total_successful_procedure_list
FROM impc_count t1
INNER JOIN (WITH 
successful_procedures_by_impc_allele_accession AS ( select impc_allele_accession_id, 
unnest(string_to_array(procedure_stable_id,'|')) as procedure_stable_id
   from impc_statistical_result
  group by impc_allele_accession_id, procedure_stable_id)
select sp.impc_allele_accession_id, count(distinct(sp.procedure_stable_id)) as count, 
   array_to_string(array_agg(distinct(sp.procedure_stable_id)),'|') as total_successful_procedure_list
   from successful_procedures_by_impc_allele_accession sp
  group by sp.impc_allele_accession_id) as t2
on t2.impc_allele_accession_id = t1.impc_allele_accession_id
WHERE
impc_count.impc_allele_accession_id = t2.impc_allele_accession_id"

# Note the revised query within the inner join handles cases
# where there are multiple procedure_stable_id for a single Solr record
# In the output file after the JSON transformation these would be concatenated.
# For example as IMPC_ABR_002|IMPC_FER_001
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "UPDATE impc_count
SET homozygous_total_successful_procedure_count = t2.count,
    homozygous_total_successful_procedure_list = t2.homozygous_total_successful_procedure_list
FROM impc_count t1
INNER JOIN (WITH
hom_successful_procedures_by_impc_allele_accession AS (select impc_allele_accession_id, 
unnest(string_to_array(procedure_stable_id,'|')) as procedure_stable_id
   from impc_statistical_result
   where zygosity='homozygote'
  group by impc_allele_accession_id, procedure_stable_id)
select hsp.impc_allele_accession_id, count(distinct(hsp.procedure_stable_id)) as count, 
   array_to_string(array_agg(distinct(hsp.procedure_stable_id)),'|') as homozygous_total_successful_procedure_list
   from hom_successful_procedures_by_impc_allele_accession hsp
  group by hsp.impc_allele_accession_id) as t2
on t2.impc_allele_accession_id = t1.impc_allele_accession_id
WHERE
impc_count.impc_allele_accession_id = t2.impc_allele_accession_id"

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "vacuum full impc_count"

# Calculation of the FUSIL bin scores for genes
#
# Take 1:1 orthologs with a support count >= 5 (categories GOOD or MODERATE)
# Human genes are all HGNC genes except those with the locus_type classified as 'readthrough'
# Ortholog assignment and data on the number of supporting calls comes from HCOP
#
# The mean achilles_gene_effect is calculated from the gene effect scores (Avana scores)
# for different cell lines found in the DepMap Achilles gene effect file.
#
# Include duplicate early adult viability calls where calls agree, along with the unique calls for a gene.
# IMPC early adult viability data is recorded under the IMPRESS parameter IMPC_VIA_001_001
#
# Rules for subdivision into the FUSIL bin categories:
# 
# Cellular Lethal (CL): IMPC lethal and mean achilles_gene_effect (Avana score) ≤ -0.45
# 
# Developmental Lethal (DL): IMPC lethal and mean achilles_gene_effect (Avana score) > -0.45
# 
# Subviable (SV): IMPC subviable and mean achilles_gene_effect (Avana score) > -0.45
# 
# Subviable Outlier (SV.outlier): IMPC subviable and mean achilles_gene_effect (Avana score) ≤ -0.45
# 
# Viable with Phenotype (VP): IMPC viable and mean achilles_gene_effect (Avana score) > -0.45, and 
#                             has one allele >= 1 significant phenotype procedure for homozygous mutant animals.
# 
# Viable No Phenotype (VN): IMPC viable and mean achilles_gene_effect (Avana score) > -0.45, and 
#                           has no allele with a significant phenotype procedure, and 
#                           has an allele where > 13 phenotype procedures have been analysed
#                           for homozygous mutant animals.
# 
# Viable Insufficient Phenotype Procedures (V.insuffProcedures): 
#                           IMPC viable and mean achilles_gene_effect (Avana score) > -0.45, and 
#                           has no allele with a significant phenotype procedure, and 
#                           has no allele where > 13 phenotype procedures have been analysed
#                           for homozygous mutant animals.
# 
# Viable Outlier (V.outlier): IMPC viable and mean achilles_gene_effect (Avana score) ≤ -0.45
#
#
# Note 
# In the subdivision of the viable category:
#
# If one allele is Viable with Phenotype, the gene is assigned Viable with Phenotype.
#
# If no allele is Viable with Phenotype, but there is a Viable No Phenotype allele, 
# the gene is Viable No Phenotype.
#
# Otherwise the Gene is assigned Viable Insufficient Phenotype Procedures,
# unless it falls into the Viable Outlier category.



# Cellular lethals
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1))
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Cellular Lethal' as \"bin\", 'CL' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v 
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Lethal' and 
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect <= -0.45
group by oo.id, bin, bin_code"


# Developmental lethals
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1))
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Developmental Lethal' as \"bin\", 'DL' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v 
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Lethal' and 
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect > -0.45
group by oo.id, bin, bin_code"


# Subviable
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1))
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Subviable' as \"bin\", 'SV' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v 
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Subviable' and 
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect > -0.45
group by oo.id, bin, bin_code"


# Subviable Outlier
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1))
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Subviable Outlier' as \"bin\", 'SV.outlier' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v 
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Subviable' and 
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect <= -0.45
group by oo.id, bin, bin_code"



# Viable With Phenotype
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1)),
mouse_genes_allele_with_significant_procedures AS (select distinct(mouse_gene_id) from impc_count where homozygous_significant_procedure_count > 0)
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Viable With Phenotype' as \"bin\", 'VP' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v 
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Viable' and
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect > -0.45 and 
mm.id IN (select mouse_gene_id from mouse_genes_allele_with_significant_procedures)
group by oo.id, bin, bin_code"


# Viable No Phenotype
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1)),
mouse_genes_allele_with_significant_procedures AS (select distinct(mouse_gene_id) from impc_count where homozygous_significant_procedure_count > 0),
mouse_genes_allele_with_sufficient_successful_procedures AS (select distinct(mouse_gene_id) from impc_count where homozygous_total_successful_procedure_count >= 13)
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Viable No Phenotype' as \"bin\", 'VN' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Viable' and
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect > -0.45 and 
mm.id NOT in (select mouse_gene_id from mouse_genes_allele_with_significant_procedures) and 
mm.id IN (select mouse_gene_id from mouse_genes_allele_with_sufficient_successful_procedures) 
group by oo.id, bin, bin_code"


# Viable Insufficient Phenotype Procedures
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1)),
mouse_genes_allele_with_significant_procedures AS (select distinct(mouse_gene_id) from impc_count where homozygous_significant_procedure_count > 0),
mouse_genes_allele_with_sufficient_successful_procedures AS (select distinct(mouse_gene_id) from impc_count where homozygous_total_successful_procedure_count >= 13),
mouse_genes_allele_with_insufficient_successful_procedures AS (select distinct(mouse_gene_id) from impc_count where homozygous_total_successful_procedure_count < 13) 
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Viable Insufficient Phenotype Procedures' as \"bin\", 'V.insuffProcedures' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Viable' and
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect > -0.45 and 
mm.id NOT in (select mouse_gene_id from mouse_genes_allele_with_significant_procedures) and 
mm.id NOT in (select mouse_gene_id from mouse_genes_allele_with_sufficient_successful_procedures) and 
mm.id in (select mouse_gene_id from mouse_genes_allele_with_insufficient_successful_procedures) 
group by oo.id, bin, bin_code"


# Viable Outlier
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "WITH
mouse_genes_with_single_human_ortholog AS (select m.mgi_gene_acc_id from mouse_gene m, ortholog o where m.id=o.mouse_gene_id and o.support_count > 4 group by m.mgi_gene_acc_id having count(distinct(o.human_gene_id)) = 1),
human_genes_with_single_mouse_ortholog AS (select h8.hgnc_acc_id from human_gene h8, ortholog o8 where h8.id=o8.human_gene_id and o8.support_count > 4 group by h8.hgnc_acc_id having count(distinct(o8.mouse_gene_id)) = 1),
mouse_genes_with_distinct_homozgous_viability_call AS ((select m3.mgi_gene_acc_id from mouse_gene m3, impc_adult_viability v3 where m3.id = v3.mouse_gene_id and v3.zygosity='homozygote' and v3.developmental_stage_name='Earlyadult' group by m3.mgi_gene_acc_id having count(distinct(v3.id)) > 1 and count(distinct(v3.category))=1) UNION (select m4.mgi_gene_acc_id from mouse_gene m4, impc_adult_viability v4 where m4.id = v4.mouse_gene_id and v4.zygosity='homozygote' and v4.developmental_stage_name='Earlyadult' group by m4.mgi_gene_acc_id having count(distinct(v4.id)) = 1))
INSERT INTO fusil (ortholog_id, bin, bin_code) 
select oo.id, 'Viable Outlier' as \"bin\", 'V.outlier' as \"bin_code\" from mouse_gene mm, human_gene hh, ortholog oo, achilles_gene_effect age, impc_adult_viability v 
where 
mm.id=oo.mouse_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_single_human_ortholog) and 
oo.support_count > 4 and 
oo.human_gene_id = hh.id and 
hh.hgnc_acc_id in (select hgnc_acc_id from human_genes_with_single_mouse_ortholog) and 
hh.id=age.human_gene_id and 
mm.mgi_gene_acc_id in (select mgi_gene_acc_id from mouse_genes_with_distinct_homozgous_viability_call) and 
mm.id = v.mouse_gene_id and 
v.zygosity='homozygote' and 
v.category='Homozygous-Viable' and 
v.developmental_stage_name='Earlyadult' and
age.mean_gene_effect <= -0.45
group by oo.id, bin, bin_code"



printf 'end=%s\n' $(date +"%s") >> /usr/local/data/postgres_processing_time.sh
printf "echo -n 'Postgresql processing time: '\n" >> /usr/local/data/postgres_processing_time.sh
echo 'printf "'"%d s\n"'" $(( $end - $start ))'   >> /usr/local/data/postgres_processing_time.sh
chmod 755 /usr/local/data/postgres_processing_time.sh