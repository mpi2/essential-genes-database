--
-- PostgreSQL database dump
--

-- Dumped from database version 11.0 (Debian 11.0-1.pgdg90+2)
-- Dumped by pg_dump version 11.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

GRANT ALL ON schema public TO batch_admin;



--
-- Name: idg_tmp; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.idg_tmp (
    id bigint NOT NULL,
    name character varying(255),
    tdl character varying(255),
    family character varying(255),
    symbol character varying(255),
    uniprot_acc_id character varying(20),
    chr character varying(255)
);


ALTER TABLE public.idg_tmp OWNER TO batch_admin;


--
-- Name: idg_tmp_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.idg_tmp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.idg_tmp_id_seq OWNER TO batch_admin;

--
-- Name: idg_tmp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.idg_tmp_id_seq OWNED BY public.idg_tmp.id;


--
-- Name: idg; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.idg (
    id bigint NOT NULL,
    human_gene_id bigint,
    name character varying(255),
    tdl character varying(255),
    family character varying(255),
    symbol character varying(255),
    uniprot_acc_id character varying(20),
    chr character varying(255)
);


ALTER TABLE public.idg OWNER TO batch_admin;

--
-- Name: idg_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.idg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.idg_id_seq OWNER TO batch_admin;

--
-- Name: idg_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.idg_id_seq OWNED BY public.idg.id;





--
-- Name: clingen_tmp; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.clingen_tmp (
    id bigint NOT NULL,
    symbol character varying(255),
    hgnc_acc_id character varying(255),
    haploinsufficiency character varying(255),
    triplosensitivity character varying(255),
    report character varying(255),
    date timestamp without time zone
);


ALTER TABLE public.clingen_tmp OWNER TO batch_admin;


--
-- Name: clingen_tmp_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.clingen_tmp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clingen_tmp_id_seq OWNER TO batch_admin;

--
-- Name: clingen_tmp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.clingen_tmp_id_seq OWNED BY public.clingen_tmp.id;


--
-- Name: clingen; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.clingen (
    id bigint NOT NULL,
    human_gene_id bigint,
    haploinsufficiency character varying(255),
    triplosensitivity character varying(255),
    report character varying(255),
    date timestamp without time zone
);


ALTER TABLE public.clingen OWNER TO batch_admin;

--
-- Name: clingen_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.clingen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clingen_id_seq OWNER TO batch_admin;

--
-- Name: clingen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.clingen_id_seq OWNED BY public.clingen.id;





--
-- Name: achillies_cell_types; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.achillies_cell_types (
    id bigint NOT NULL,
    cell_type_names text
);


ALTER TABLE public.achillies_cell_types OWNER TO batch_admin;


--
-- Name: achillies_cell_types_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.achillies_cell_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.achillies_cell_types_id_seq OWNER TO batch_admin;

--
-- Name: achillies_cell_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.achillies_cell_types_id_seq OWNED BY public.achillies_cell_types.id;






--
-- Name: achilles_gene_effect_raw; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.achilles_gene_effect_raw (
    id bigint NOT NULL,
    symbol character varying(255),
    entrez_acc_id bigint,
    cell_type_data text,
    cell_type_name_id bigint
);


ALTER TABLE public.achilles_gene_effect_raw OWNER TO batch_admin;


--
-- Name: achilles_gene_effect_raw_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.achilles_gene_effect_raw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.achilles_gene_effect_raw_id_seq OWNER TO batch_admin;

--
-- Name: achilles_gene_effect_raw_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.achilles_gene_effect_raw_id_seq OWNED BY public.achilles_gene_effect_raw.id;


--
-- Name: achilles_gene_effect; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.achilles_gene_effect (
    id bigint NOT NULL,
    human_gene_id bigint,
    raw_data_id bigint,
    entrez_acc_id bigint,
    mean_gene_effect float8
);


ALTER TABLE public.achilles_gene_effect OWNER TO batch_admin;

--
-- Name: achilles_gene_effect_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.achilles_gene_effect_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.achilles_gene_effect_id_seq OWNER TO batch_admin;

--
-- Name: achilles_gene_effect_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.achilles_gene_effect_id_seq OWNED BY public.achilles_gene_effect.id;







--
-- Name: gnomad_plof_tmp; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.gnomad_plof_tmp (
    id bigint NOT NULL,
    gene_symbol character varying(255),
    transcript character varying(255),
    obs_mis bigint,
    exp_mis double precision,
    oe_mis double precision,
    mu_mis double precision,
    possible_mis bigint,
    obs_mis_pphen bigint,
    exp_mis_pphen double precision,
    oe_mis_pphen double precision,
    possible_mis_pphen bigint,
    obs_syn bigint,
    exp_syn double precision,
    oe_syn double precision,
    mu_syn double precision,
    possible_syn bigint,
    obs_lof bigint,
    mu_lof double precision,
    possible_lof bigint,
    exp_lof double precision,
    pLI double precision,
    pNull double precision,
    pRec double precision,
    oe_lof double precision,
    oe_syn_lower double precision,
    oe_syn_upper double precision,
    oe_mis_lower double precision,
    oe_mis_upper double precision,
    oe_lof_lower double precision,
    oe_lof_upper double precision,
    constraint_flag character varying(2048),
    syn_z double precision,
    mis_z double precision,
    lof_z   double precision,
    oe_lof_upper_rank bigint,
    oe_lof_upper_bin bigint,
    oe_lof_upper_bin_6 bigint,
    n_sites bigint,
    classic_caf double precision,
    max_af double precision,
    no_lofs bigint,
    obs_het_lof bigint,
    obs_hom_lof bigint,
    defined bigint,
    p double precision,
    exp_hom_lof double precision,
    classic_caf_afr double precision,
    classic_caf_amr double precision,
    classic_caf_asj double precision,
    classic_caf_eas double precision,
    classic_caf_fin double precision,
    classic_caf_nfe double precision,
    classic_caf_oth double precision,
    classic_caf_sas double precision,
    p_afr double precision,
    p_amr double precision,
    p_asj double precision,
    p_eas double precision,
    p_fin double precision,
    p_nfe double precision,
    p_oth double precision,
    p_sas double precision,
    transcript_type character varying(255),
    gene_id character varying(255),
    transcript_level bigint,
    cds_length bigint,
    num_coding_exons bigint,
    gene_type character varying(255),
    gene_length bigint,
    exac_pLI double precision,
    exac_obs_lof bigint,
    exac_exp_lof double precision,
    exac_oe_lof double precision,
    brain_expression character varying(255),
    chromosome character varying(255),
    start_position bigint,
    end_position bigint
);


ALTER TABLE public.gnomad_plof_tmp OWNER TO batch_admin;


--
-- Name: gnomad_plof_tmp_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.gnomad_plof_tmp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gnomad_plof_tmp_id_seq OWNER TO batch_admin;

--
-- Name: gnomad_plof_tmp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.gnomad_plof_tmp_id_seq OWNED BY public.gnomad_plof_tmp.id;


--
-- Name: gnomad_plof; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.gnomad_plof (
    id bigint NOT NULL,
    human_gene_id bigint,
    gene_symbol character varying(255),
    transcript character varying(255),
    obs_mis bigint,
    exp_mis double precision,
    oe_mis double precision,
    mu_mis double precision,
    possible_mis bigint,
    obs_mis_pphen bigint,
    exp_mis_pphen double precision,
    oe_mis_pphen double precision,
    possible_mis_pphen bigint,
    obs_syn bigint,
    exp_syn double precision,
    oe_syn double precision,
    mu_syn double precision,
    possible_syn bigint,
    obs_lof bigint,
    mu_lof double precision,
    possible_lof bigint,
    exp_lof double precision,
    pLI double precision,
    pNull double precision,
    pRec double precision,
    oe_lof double precision,
    oe_syn_lower double precision,
    oe_syn_upper double precision,
    oe_mis_lower double precision,
    oe_mis_upper double precision,
    oe_lof_lower double precision,
    oe_lof_upper double precision,
    constraint_flag character varying(2048),
    syn_z double precision,
    mis_z double precision,
    lof_z   double precision,
    oe_lof_upper_rank bigint,
    oe_lof_upper_bin bigint,
    oe_lof_upper_bin_6 bigint,
    n_sites bigint,
    classic_caf double precision,
    max_af double precision,
    no_lofs bigint,
    obs_het_lof bigint,
    obs_hom_lof bigint,
    defined bigint,
    p double precision,
    exp_hom_lof double precision,
    classic_caf_afr double precision,
    classic_caf_amr double precision,
    classic_caf_asj double precision,
    classic_caf_eas double precision,
    classic_caf_fin double precision,
    classic_caf_nfe double precision,
    classic_caf_oth double precision,
    classic_caf_sas double precision,
    p_afr double precision,
    p_amr double precision,
    p_asj double precision,
    p_eas double precision,
    p_fin double precision,
    p_nfe double precision,
    p_oth double precision,
    p_sas double precision,
    transcript_type character varying(255),
    gene_id character varying(255),
    transcript_level bigint,
    cds_length bigint,
    num_coding_exons bigint,
    gene_type character varying(255),
    gene_length bigint,
    exac_pLI double precision,
    exac_obs_lof bigint,
    exac_exp_lof double precision,
    exac_oe_lof double precision,
    brain_expression character varying(255),
    chromosome character varying(255),
    start_position bigint,
    end_position bigint
);


ALTER TABLE public.gnomad_plof OWNER TO batch_admin;

--
-- Name: gnomad_plof_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.gnomad_plof_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gnomad_plof_id_seq OWNER TO batch_admin;

--
-- Name: gnomad_plof_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.gnomad_plof_id_seq OWNED BY public.gnomad_plof.id;





--
-- Name: impc_embryo_viability_tmp; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.impc_embryo_viability_tmp (
    id bigint NOT NULL,
    parameter_stable_id character varying(255),
    project_id character varying(255),
    project_name character varying(255),
    procedure_group character varying(255),
    procedure_stable_id character varying(255),
    pipeline_stable_id character varying(255),
    pipeline_name character varying(255),
    phenotyping_center_id character varying(255),
    phenotyping_center character varying(255),
    developmental_stage_acc character varying(255),
    developmental_stage_name character varying(255),
    gene_symbol character varying(255),
    gene_accession_id character varying(255),
    colony_id character varying(255),
    biological_sample_group character varying(255),
    experiment_source_id character varying(255),
    allele_accession_id character varying(255),
    allele_symbol character varying(255),
    allelic_composition character varying(255),
    genetic_background character varying(255),
    strain_accession_id character varying(255),
    strain_name character varying(255),
    zygosity character varying(255),
    sex character varying(255),
    category character varying(255),
    parameter_name character varying(255),
    procedure_name character varying(255)
);


ALTER TABLE public.impc_embryo_viability_tmp OWNER TO batch_admin;


--
-- Name: impc_embryo_viability_tmp_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_embryo_viability_tmp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_embryo_viability_tmp_id_seq OWNER TO batch_admin;

--
-- Name: impc_embryo_viability_tmp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_embryo_viability_tmp_id_seq OWNED BY public.impc_embryo_viability_tmp.id;


--
-- Name: impc_embryo_viability; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.impc_embryo_viability (
    id bigint NOT NULL,
    mouse_gene_id bigint,
    parameter_stable_id character varying(255),
    project_id character varying(255),
    project_name character varying(255),
    procedure_group character varying(255),
    procedure_stable_id character varying(255),
    pipeline_stable_id character varying(255),
    pipeline_name character varying(255),
    phenotyping_center_id character varying(255),
    phenotyping_center character varying(255),
    developmental_stage_acc character varying(255),
    developmental_stage_name character varying(255),
    gene_symbol character varying(255),
    gene_accession_id character varying(255),
    colony_id character varying(255),
    biological_sample_group character varying(255),
    experiment_source_id character varying(255),
    allele_accession_id character varying(255),
    allele_symbol character varying(255),
    allelic_composition character varying(255),
    genetic_background character varying(255),
    strain_accession_id character varying(255),
    strain_name character varying(255),
    zygosity character varying(255),
    sex character varying(255),
    category character varying(255),
    parameter_name character varying(255),
    procedure_name character varying(255)
);


ALTER TABLE public.impc_embryo_viability OWNER TO batch_admin;

--
-- Name: impc_embryo_viability_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_embryo_viability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_embryo_viability_id_seq OWNER TO batch_admin;

--
-- Name: impc_embryo_viability_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_embryo_viability_id_seq OWNED BY public.impc_embryo_viability.id;








--
-- Name: impc_adult_viability_tmp; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.impc_adult_viability_tmp (
    id bigint NOT NULL,
    parameter_stable_id character varying(255),
    project_id character varying(255),
    project_name character varying(255),
    procedure_group character varying(255),
    procedure_stable_id character varying(255),
    pipeline_stable_id character varying(255),
    pipeline_name character varying(255),
    phenotyping_center_id character varying(255),
    phenotyping_center character varying(255),
    developmental_stage_acc character varying(255),
    developmental_stage_name character varying(255),
    gene_symbol character varying(255),
    gene_accession_id character varying(255),
    colony_id character varying(255),
    biological_sample_group character varying(255),
    experiment_source_id character varying(255),
    allele_accession_id character varying(255),
    allele_symbol character varying(255),
    allelic_composition character varying(255),
    genetic_background character varying(255),
    strain_accession_id character varying(255),
    strain_name character varying(255),
    zygosity character varying(255),
    sex character varying(255),
    category character varying(255),
    parameter_name character varying(255),
    procedure_name character varying(255)
);


ALTER TABLE public.impc_adult_viability_tmp OWNER TO batch_admin;


--
-- Name: impc_adult_viability_tmp_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_adult_viability_tmp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_adult_viability_tmp_id_seq OWNER TO batch_admin;

--
-- Name: impc_adult_viability_tmp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_adult_viability_tmp_id_seq OWNED BY public.impc_adult_viability_tmp.id;


--
-- Name: impc_adult_viability; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.impc_adult_viability (
    id bigint NOT NULL,
    mouse_gene_id bigint,
    parameter_stable_id character varying(255),
    project_id character varying(255),
    project_name character varying(255),
    procedure_group character varying(255),
    procedure_stable_id character varying(255),
    pipeline_stable_id character varying(255),
    pipeline_name character varying(255),
    phenotyping_center_id character varying(255),
    phenotyping_center character varying(255),
    developmental_stage_acc character varying(255),
    developmental_stage_name character varying(255),
    gene_symbol character varying(255),
    gene_accession_id character varying(255),
    colony_id character varying(255),
    biological_sample_group character varying(255),
    experiment_source_id character varying(255),
    allele_accession_id character varying(255),
    allele_symbol character varying(255),
    allelic_composition character varying(255),
    genetic_background character varying(255),
    strain_accession_id character varying(255),
    strain_name character varying(255),
    zygosity character varying(255),
    sex character varying(255),
    category character varying(255),
    parameter_name character varying(255),
    procedure_name character varying(255)
);


ALTER TABLE public.impc_adult_viability OWNER TO batch_admin;

--
-- Name: impc_adult_viability_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_adult_viability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_adult_viability_id_seq OWNER TO batch_admin;

--
-- Name: impc_adult_viability_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_adult_viability_id_seq OWNED BY public.impc_adult_viability.id;












--
-- Name: impc_significant_phenotype_tmp; Type: TABLE; Schema: public; Owner: batch_admin
--



CREATE TABLE public.impc_significant_phenotype_tmp (
    id bigint NOT NULL,
    assertion_type character varying(255),
    assertion_type_id character varying(255),
    mp_term_id character varying(255),
    mp_term_name character varying(255),
    top_level_mp_term_ids text,
    top_level_mp_term_names text,
    intermediate_mp_term_ids text,
    intermediate_mp_term_names text,
    impc_marker_symbol character varying(255),
    impc_marker_accession_id character varying(255),
    colony_id character varying(255),
    impc_allele_name text,
    impc_allele_symbol character varying(255),
    impc_allele_accession_id character varying(255),
    impc_strain_name character varying(255),
    impc_strain_accession_id character varying(255),
    phenotyping_center character varying(255),
    project_name character varying(255),
    resource_name character varying(255),
    sex character varying(255),
    zygosity character varying(255),
    pipeline_name character varying(255),
    pipeline_stable_id character varying(255),
    procedure_name character varying(255),
    procedure_stable_id character varying(255),
    parameter_name character varying(255),
    parameter_stable_id character varying(255),
    statistical_method character varying(255),
    p_value float8,
    effect_size float8,
    life_stage_acc character varying(255),
    life_stage_name character varying(255)
);


ALTER TABLE public.impc_significant_phenotype_tmp OWNER TO batch_admin;


--
-- Name: impc_significant_phenotype_tmp_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_significant_phenotype_tmp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_significant_phenotype_tmp_id_seq OWNER TO batch_admin;

--
-- Name: impc_significant_phenotype_tmp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_significant_phenotype_tmp_id_seq OWNED BY public.impc_significant_phenotype_tmp.id;


--
-- Name: impc_significant_phenotype; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.impc_significant_phenotype (
    id bigint NOT NULL,
    mouse_gene_id bigint,
    assertion_type character varying(255),
    assertion_type_id character varying(255),
    mp_term_id character varying(255),
    mp_term_name character varying(255),
    top_level_mp_term_ids text,
    top_level_mp_term_names text,
    intermediate_mp_term_ids text,
    intermediate_mp_term_names text,
    impc_marker_symbol character varying(255),
    impc_marker_accession_id character varying(255),
    colony_id character varying(255),
    impc_allele_name text,
    impc_allele_symbol character varying(255),
    impc_allele_accession_id character varying(255),
    impc_strain_name character varying(255),
    impc_strain_accession_id character varying(255),
    phenotyping_center character varying(255),
    project_name character varying(255),
    resource_name character varying(255),
    sex character varying(255),
    zygosity character varying(255),
    pipeline_name character varying(255),
    pipeline_stable_id character varying(255),
    procedure_name character varying(255),
    procedure_stable_id character varying(255),
    parameter_name character varying(255),
    parameter_stable_id character varying(255),
    statistical_method character varying(255),
    p_value float8,
    effect_size float8,
    life_stage_acc character varying(255),
    life_stage_name character varying(255)
);


ALTER TABLE public.impc_significant_phenotype OWNER TO batch_admin;

--
-- Name: impc_significant_phenotype_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_significant_phenotype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_significant_phenotype_id_seq OWNER TO batch_admin;

--
-- Name: impc_significant_phenotype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_significant_phenotype_id_seq OWNED BY public.impc_significant_phenotype.id;







--
-- Name: impc_statistical_result; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.impc_statistical_result (
    id bigint NOT NULL,
    doc_id character varying(255),
    db_id bigint,
    data_type character varying(255),
    mp_term_id character varying(255),
    mp_term_name character varying(255),
    top_level_mp_term_ids text,
    top_level_mp_term_names text,
    life_stage_acc character varying(255),
    life_stage_name character varying(255),
    project_name character varying(255),
    phenotyping_center character varying(255),
    pipeline_stable_id character varying(255),
    pipeline_stable_key bigint,
    pipeline_name character varying(255),
    pipeline_id bigint,
    procedure_stable_id character varying(255),
    procedure_stable_key bigint,
    procedure_name character varying(255),
    procedure_id bigint,
    parameter_stable_id character varying(255),
    parameter_stable_key bigint,
    parameter_name character varying(255),
    parameter_id bigint,
    colony_id character varying(255),
    impc_marker_symbol character varying(255),
    impc_marker_accession_id character varying(255),
    impc_allele_symbol character varying(255),
    impc_allele_name text,
    impc_allele_accession_id character varying(255),
    impc_strain_name character varying(255),
    impc_strain_accession_id character varying(255),
    genetic_background character varying(255),
    zygosity character varying(255),
    status character varying(255),
    p_value float8,
    significant boolean
);


ALTER TABLE public.impc_statistical_result OWNER TO batch_admin;

--
-- Name: impc_statistical_result_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_statistical_result_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_statistical_result_id_seq OWNER TO batch_admin;

--
-- Name: impc_statistical_result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_statistical_result_id_seq OWNED BY public.impc_statistical_result.id;






















--
-- Name: impc_count; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.impc_count (
    id bigint NOT NULL,
    mouse_gene_id bigint,
    impc_marker_symbol character varying(255),
    impc_marker_accession_id character varying(255),
    impc_allele_symbol character varying(255),
    impc_allele_accession_id character varying(255),
    significant_procedure_count bigint DEFAULT 0,
    significant_procedure_list text,
    homozygous_significant_procedure_count bigint DEFAULT 0,
    homozygous_significant_procedure_list text,
    total_successful_procedure_count bigint DEFAULT 0,
    total_successful_procedure_list text,
    homozygous_total_successful_procedure_count bigint DEFAULT 0,
    homozygous_total_successful_procedure_list text
);


ALTER TABLE public.impc_count OWNER TO batch_admin;

--
-- Name: impc_count_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.impc_count_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.impc_count_id_seq OWNER TO batch_admin;

--
-- Name: impc_count_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.impc_count_id_seq OWNED BY public.impc_count.id;
















--
-- Name: fusil; Type: TABLE; Schema: public; Owner: batch_admin
--

CREATE TABLE public.fusil (
    id bigint NOT NULL,
    mouse_gene_id bigint,
    bin character varying(255),
    bin_code character varying(255)
);


ALTER TABLE public.fusil OWNER TO batch_admin;

--
-- Name: fusil_id_seq; Type: SEQUENCE; Schema: public; Owner: batch_admin
--

CREATE SEQUENCE public.fusil_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fusil_id_seq OWNER TO batch_admin;

--
-- Name: fusil_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: batch_admin
--

ALTER SEQUENCE public.fusil_id_seq OWNED BY public.fusil.id;










--
-- Name: idg_tmp id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.idg_tmp ALTER COLUMN id SET DEFAULT nextval('public.idg_tmp_id_seq'::regclass);


--
-- Name: idg id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.idg ALTER COLUMN id SET DEFAULT nextval('public.idg_id_seq'::regclass);



--
-- Name: clingen_tmp id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.clingen_tmp ALTER COLUMN id SET DEFAULT nextval('public.clingen_tmp_id_seq'::regclass);


--
-- Name: clingen id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.clingen ALTER COLUMN id SET DEFAULT nextval('public.clingen_id_seq'::regclass);




--
-- Name: achillies_cell_types id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achillies_cell_types ALTER COLUMN id SET DEFAULT nextval('public.achillies_cell_types_id_seq'::regclass);


--
-- Name: achilles_gene_effect_raw id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achilles_gene_effect_raw ALTER COLUMN id SET DEFAULT nextval('public.achilles_gene_effect_raw_id_seq'::regclass);


--
-- Name: achilles_gene_effect id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achilles_gene_effect ALTER COLUMN id SET DEFAULT nextval('public.achilles_gene_effect_id_seq'::regclass);


--
-- Name: gnomad_plof_tmp id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.gnomad_plof_tmp ALTER COLUMN id SET DEFAULT nextval('public.gnomad_plof_tmp_id_seq'::regclass);


--
-- Name: gnomad_plof id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.gnomad_plof ALTER COLUMN id SET DEFAULT nextval('public.gnomad_plof_id_seq'::regclass);




--
-- Name: impc_embryo_viability_tmp id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_embryo_viability_tmp ALTER COLUMN id SET DEFAULT nextval('public.impc_embryo_viability_tmp_id_seq'::regclass);


--
-- Name: impc_embryo_viability id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_embryo_viability ALTER COLUMN id SET DEFAULT nextval('public.impc_embryo_viability_id_seq'::regclass);



--
-- Name: impc_adult_viability_tmp id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_adult_viability_tmp ALTER COLUMN id SET DEFAULT nextval('public.impc_adult_viability_tmp_id_seq'::regclass);


--
-- Name: impc_adult_viability id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_adult_viability ALTER COLUMN id SET DEFAULT nextval('public.impc_adult_viability_id_seq'::regclass);



--
-- Name: impc_significant_phenotype_tmp id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_significant_phenotype_tmp ALTER COLUMN id SET DEFAULT nextval('public.impc_significant_phenotype_tmp_id_seq'::regclass);


--
-- Name: impc_significant_phenotype id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_significant_phenotype ALTER COLUMN id SET DEFAULT nextval('public.impc_significant_phenotype_id_seq'::regclass);




--
-- Name: impc_statistical_result id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_statistical_result ALTER COLUMN id SET DEFAULT nextval('public.impc_statistical_result_id_seq'::regclass);




--
-- Name: impc_count id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_count ALTER COLUMN id SET DEFAULT nextval('public.impc_count_id_seq'::regclass);



--
-- Name: fusil id; Type: DEFAULT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.fusil ALTER COLUMN id SET DEFAULT nextval('public.fusil_id_seq'::regclass);









--
-- Name: idg_tmp idg_tmp_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.idg_tmp
    ADD CONSTRAINT idg_tmp_pkey PRIMARY KEY (id);


--
-- Name: idg idg_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.idg
    ADD CONSTRAINT idg_pkey PRIMARY KEY (id);




--
-- Name: clingen_tmp clingen_tmp_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.clingen_tmp
    ADD CONSTRAINT clingen_tmp_pkey PRIMARY KEY (id);


--
-- Name: clingen clingen_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.clingen
    ADD CONSTRAINT clingen_pkey PRIMARY KEY (id);




--
-- Name: achillies_cell_types achillies_cell_types_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achillies_cell_types
    ADD CONSTRAINT achillies_cell_types_pkey PRIMARY KEY (id);


--
-- Name: achilles_gene_effect_raw achilles_gene_effect_raw_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achilles_gene_effect_raw
    ADD CONSTRAINT achilles_gene_effect_raw_pkey PRIMARY KEY (id);


--
-- Name: achilles_gene_effect achilles_gene_effect_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achilles_gene_effect
    ADD CONSTRAINT achilles_gene_effect_pkey PRIMARY KEY (id);



--
-- Name: gnomad_plof_tmp gnomad_plof_tmp_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.gnomad_plof_tmp
    ADD CONSTRAINT gnomad_plof_tmp_pkey PRIMARY KEY (id);


--
-- Name: gnomad_plof gnomad_plof_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.gnomad_plof
    ADD CONSTRAINT gnomad_plof_pkey PRIMARY KEY (id);




--
-- Name: impc_embryo_viability_tmp impc_embryo_viability_tmp_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_embryo_viability_tmp
    ADD CONSTRAINT impc_embryo_viability_tmp_pkey PRIMARY KEY (id);


--
-- Name: impc_embryo_viability impc_embryo_viability_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_embryo_viability
    ADD CONSTRAINT impc_embryo_viability_pkey PRIMARY KEY (id);




--
-- Name: impc_adult_viability_tmp impc_adult_viability_tmp_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_adult_viability_tmp
    ADD CONSTRAINT impc_adult_viability_tmp_pkey PRIMARY KEY (id);


--
-- Name: impc_adult_viability impc_adult_viability_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_adult_viability
    ADD CONSTRAINT impc_adult_viability_pkey PRIMARY KEY (id);




--
-- Name: impc_significant_phenotype_tmp impc_significant_phenotype_tmp_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_significant_phenotype_tmp
    ADD CONSTRAINT impc_significant_phenotype_tmp_pkey PRIMARY KEY (id);


--
-- Name: impc_significant_phenotype impc_significant_phenotype_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_significant_phenotype
    ADD CONSTRAINT impc_significant_phenotype_pkey PRIMARY KEY (id);





--
-- Name: impc_statistical_result impc_statistical_result_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_statistical_result
    ADD CONSTRAINT impc_statistical_result_pkey PRIMARY KEY (id);


--
-- Name: impc_count impc_count_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_count
    ADD CONSTRAINT impc_count_pkey PRIMARY KEY (id);




--
-- Name: fusil fusil_pkey; Type: CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.fusil
    ADD CONSTRAINT fusil_pkey PRIMARY KEY (id);









--
-- Name: idg fk993i1het18j033e8a67r63t9; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.idg
    ADD CONSTRAINT fk993i1het18j033e8a67r63t9 FOREIGN KEY (human_gene_id) REFERENCES public.human_gene(id);




--
-- Name: clingen fk963i1her18j033e8a67r63t2; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.clingen
    ADD CONSTRAINT fk963i1her18j033e8a67r63t2 FOREIGN KEY (human_gene_id) REFERENCES public.human_gene(id);




--
-- Name: achilles_gene_effect fk961a1heb18j033e8a67r63t6; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achilles_gene_effect
    ADD CONSTRAINT fk961a1heb18j033e8a67r63t6 FOREIGN KEY (human_gene_id) REFERENCES public.human_gene(id);

--
-- Name: achilles_gene_effect fk967b1heb18j077e8a67r63t6; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achilles_gene_effect
    ADD CONSTRAINT fk967b1heb18j077e8a67r63t6 FOREIGN KEY (raw_data_id) REFERENCES public.achilles_gene_effect_raw(id);




--
-- Name: achilles_gene_effect_raw fk969u1heb18j099e8a67r63t8; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.achilles_gene_effect_raw
    ADD CONSTRAINT fk969u1heb18j099e8a67r63t8 FOREIGN KEY (cell_type_name_id) REFERENCES public.achillies_cell_types(id);



--
-- Name: gnomad_plof fk729a1ton18a028e8a43r23o8; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.gnomad_plof
    ADD CONSTRAINT fk729a1ton18a028e8a43r23o8 FOREIGN KEY (human_gene_id) REFERENCES public.human_gene(id);


--
-- Name: impc_embryo_viability fk953i1eot18j033e8a67r63t7; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_embryo_viability
    ADD CONSTRAINT fk953i1eot18j033e8a67r63t7 FOREIGN KEY (mouse_gene_id) REFERENCES public.mouse_gene(id);



--
-- Name: impc_adult_viability fk929i1heu94j033e8a69r63a1; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_adult_viability
    ADD CONSTRAINT fk929i1heu94j033e8a69r63a1 FOREIGN KEY (mouse_gene_id) REFERENCES public.mouse_gene(id);



--
-- Name: impc_significant_phenotype fk489a8hau92y052e8a69r61e7; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_significant_phenotype
    ADD CONSTRAINT fk489a8hau92y052e8a69r61e7 FOREIGN KEY (mouse_gene_id) REFERENCES public.mouse_gene(id);




--
-- Name: impc_count fk278i4uwt83i016e9b69r73a1; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.impc_count
    ADD CONSTRAINT fk278i4uwt83i016e9b69r73a1 FOREIGN KEY (mouse_gene_id) REFERENCES public.mouse_gene(id);




--
-- Name: fusil fk427m9tau92y023e8a69r54e9; Type: FK CONSTRAINT; Schema: public; Owner: batch_admin
--

ALTER TABLE ONLY public.fusil
    ADD CONSTRAINT fk427m9tau92y023e8a69r54e9 FOREIGN KEY (mouse_gene_id) REFERENCES public.mouse_gene(id);








-- 
-- Schema Search PATH
-- 

-- 
-- Need to specify the schema search path
-- The default is:
-- "$user", public
-- However this is causing an issue when specifying the SQL in the docker container.


SET search_path TO hdb_catalog, hdb_views, public;


-- 
-- Hasura user - Note only select granted on tables - i.e. read-only
-- 


-- We will create a separate user and grant permissions on hasura-specific
-- schemas and information_schema and pg_catalog
-- These permissions/grants are required for Hasura to work properly.

-- create a separate user for hasura
CREATE USER hasurauser WITH PASSWORD 'hasurauser';

-- create pgcrypto extension, required for UUID
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- create the schemas required by the hasura system
-- NOTE: If you are starting from scratch: drop the below schemas first, if they exist.
CREATE SCHEMA IF NOT EXISTS hdb_catalog;
CREATE SCHEMA IF NOT EXISTS hdb_views;

-- make the user an owner of system schemas
ALTER SCHEMA hdb_catalog OWNER TO hasurauser;
ALTER SCHEMA hdb_views OWNER TO hasurauser;

-- grant select permissions on information_schema and pg_catalog. This is
-- required for hasura to query list of available tables
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO hasurauser;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO hasurauser;

-- Below permissions are optional. This is dependent on what access to your
-- tables/schemas - you want give to hasura. If you want expose the public
-- schema for GraphQL query then give permissions on public schema to the
-- hasura user.
-- Be careful to use these in your production db. Consult the postgres manual or
-- your DBA and give appropriate permissions.

-- grant all privileges on all tables in the public schema. This can be customised:
-- For example, if you only want to use GraphQL regular queries and not mutations,
-- then you can set: GRANT SELECT ON ALL TABLES...


REVOKE ALL ON SCHEMA public FROM hasurauser;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM hasurauser;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO hasurauser;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO hasurauser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO hasurauser;

-- 
-- Prevent Hasura from adding additional tables or triggers
-- Make sure run ALTER DEFAULT as hasurauser

ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON SEQUENCES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON ROUTINES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON TYPES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON SCHEMAS FROM PUBLIC;

ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON TABLES FROM hasurauser;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON SEQUENCES FROM hasurauser;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON FUNCTIONS FROM hasurauser;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON ROUTINES FROM hasurauser;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON TYPES FROM hasurauser;
ALTER DEFAULT PRIVILEGES FOR ROLE hasurauser REVOKE ALL PRIVILEGES ON SCHEMAS FROM hasurauser;

-- Similarly add this for other schemas, if you have any.
-- GRANT USAGE ON SCHEMA <schema-name> TO hasurauser;
-- GRANT ALL ON ALL TABLES IN SCHEMA <schema-name> TO hasurauser;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA <schema-name> TO hasurauser;











