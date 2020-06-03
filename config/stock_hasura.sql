--
-- PostgreSQL database dump
--

-- Dumped from database version 11.3 (Debian 11.3-1.pgdg90+1)
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

--
-- Name: hdb_catalog; Type: SCHEMA; Schema: -; Owner: hasurauser
--

CREATE SCHEMA IF NOT EXISTS hdb_catalog;


ALTER SCHEMA hdb_catalog OWNER TO hasurauser;

--
-- Name: hdb_schema_update_event_notifier(); Type: FUNCTION; Schema: hdb_catalog; Owner: hasurauser
--

CREATE FUNCTION hdb_catalog.hdb_schema_update_event_notifier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    instance_id uuid;
    occurred_at timestamptz;
    curr_rec record;
  BEGIN
    instance_id = NEW.instance_id;
    occurred_at = NEW.occurred_at;
    PERFORM pg_notify('hasura_schema_update', json_build_object(
      'instance_id', instance_id,
      'occurred_at', occurred_at
      )::text);
    RETURN curr_rec;
  END;
$$;


ALTER FUNCTION hdb_catalog.hdb_schema_update_event_notifier() OWNER TO hasurauser;

--
-- Name: hdb_table_oid_check(); Type: FUNCTION; Schema: hdb_catalog; Owner: hasurauser
--

CREATE FUNCTION hdb_catalog.hdb_table_oid_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (EXISTS (SELECT 1 FROM information_schema.tables st WHERE st.table_schema = NEW.table_schema AND st.table_name = NEW.table_name)) THEN
      return NEW;
    ELSE
      RAISE foreign_key_violation using message = 'table_schema, table_name not in information_schema.tables';
      return NULL;
    END IF;
  END;
$$;


ALTER FUNCTION hdb_catalog.hdb_table_oid_check() OWNER TO hasurauser;

--
-- Name: inject_table_defaults(text, text, text, text); Type: FUNCTION; Schema: hdb_catalog; Owner: hasurauser
--

CREATE FUNCTION hdb_catalog.inject_table_defaults(view_schema text, view_name text, tab_schema text, tab_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE
        r RECORD;
    BEGIN
      FOR r IN SELECT column_name, column_default FROM information_schema.columns WHERE table_schema = tab_schema AND table_name = tab_name AND column_default IS NOT NULL LOOP
          EXECUTE format('ALTER VIEW %I.%I ALTER COLUMN %I SET DEFAULT %s;', view_schema, view_name, r.column_name, r.column_default);
      END LOOP;
    END;
$$;


ALTER FUNCTION hdb_catalog.inject_table_defaults(view_schema text, view_name text, tab_schema text, tab_name text) OWNER TO hasurauser;

--
-- Name: insert_event_log(text, text, text, text, json); Type: FUNCTION; Schema: hdb_catalog; Owner: hasurauser
--

CREATE FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) RETURNS text
    LANGUAGE plpgsql
    AS $$
  DECLARE
    id text;
    payload json;
    session_variables json;
    server_version_num int;
  BEGIN
    id := gen_random_uuid();
    server_version_num := current_setting('server_version_num');
    IF server_version_num >= 90600 THEN
      session_variables := current_setting('hasura.user', 't');
    ELSE
      BEGIN
        session_variables := current_setting('hasura.user');
      EXCEPTION WHEN OTHERS THEN
                  session_variables := NULL;
      END;
    END IF;
    payload := json_build_object(
      'op', op,
      'data', row_data,
      'session_variables', session_variables
    );
    INSERT INTO hdb_catalog.event_log
                (id, schema_name, table_name, trigger_name, payload)
    VALUES
    (id, schema_name, table_name, trigger_name, payload);
    RETURN id;
  END;
$$;


ALTER FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) OWNER TO hasurauser;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.event_invocation_logs (
    id text DEFAULT public.gen_random_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.event_invocation_logs OWNER TO hasurauser;

--
-- Name: event_log; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.event_log (
    id text DEFAULT public.gen_random_uuid() NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    trigger_name text NOT NULL,
    payload jsonb NOT NULL,
    delivered boolean DEFAULT false NOT NULL,
    error boolean DEFAULT false NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    locked boolean DEFAULT false NOT NULL,
    next_retry_at timestamp without time zone
);


ALTER TABLE hdb_catalog.event_log OWNER TO hasurauser;

--
-- Name: event_triggers; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.event_triggers (
    name text NOT NULL,
    type text NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    configuration json,
    comment text
);


ALTER TABLE hdb_catalog.event_triggers OWNER TO hasurauser;

--
-- Name: hdb_allowlist; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_allowlist (
    collection_name text
);


ALTER TABLE hdb_catalog.hdb_allowlist OWNER TO hasurauser;

--
-- Name: hdb_check_constraint; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_check_constraint AS
 SELECT (n.nspname)::text AS table_schema,
    (ct.relname)::text AS table_name,
    (r.conname)::text AS constraint_name,
    pg_get_constraintdef(r.oid, true) AS "check"
   FROM ((pg_constraint r
     JOIN pg_class ct ON ((r.conrelid = ct.oid)))
     JOIN pg_namespace n ON ((ct.relnamespace = n.oid)))
  WHERE (r.contype = 'c'::"char");


ALTER TABLE hdb_catalog.hdb_check_constraint OWNER TO hasurauser;

--
-- Name: hdb_foreign_key_constraint; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_foreign_key_constraint AS
 SELECT (q.table_schema)::text AS table_schema,
    (q.table_name)::text AS table_name,
    (q.constraint_name)::text AS constraint_name,
    (min(q.constraint_oid))::integer AS constraint_oid,
    min((q.ref_table_table_schema)::text) AS ref_table_table_schema,
    min((q.ref_table)::text) AS ref_table,
    json_object_agg(ac.attname, afc.attname) AS column_mapping,
    min((q.confupdtype)::text) AS on_update,
    min((q.confdeltype)::text) AS on_delete
   FROM ((( SELECT ctn.nspname AS table_schema,
            ct.relname AS table_name,
            r.conrelid AS table_id,
            r.conname AS constraint_name,
            r.oid AS constraint_oid,
            cftn.nspname AS ref_table_table_schema,
            cft.relname AS ref_table,
            r.confrelid AS ref_table_id,
            r.confupdtype,
            r.confdeltype,
            unnest(r.conkey) AS column_id,
            unnest(r.confkey) AS ref_column_id
           FROM ((((pg_constraint r
             JOIN pg_class ct ON ((r.conrelid = ct.oid)))
             JOIN pg_namespace ctn ON ((ct.relnamespace = ctn.oid)))
             JOIN pg_class cft ON ((r.confrelid = cft.oid)))
             JOIN pg_namespace cftn ON ((cft.relnamespace = cftn.oid)))
          WHERE (r.contype = 'f'::"char")) q
     JOIN pg_attribute ac ON (((q.column_id = ac.attnum) AND (q.table_id = ac.attrelid))))
     JOIN pg_attribute afc ON (((q.ref_column_id = afc.attnum) AND (q.ref_table_id = afc.attrelid))))
  GROUP BY q.table_schema, q.table_name, q.constraint_name;


ALTER TABLE hdb_catalog.hdb_foreign_key_constraint OWNER TO hasurauser;

--
-- Name: hdb_function; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_function (
    function_schema text NOT NULL,
    function_name text NOT NULL,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_function OWNER TO hasurauser;

--
-- Name: hdb_function_agg; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_function_agg AS
 SELECT (p.proname)::text AS function_name,
    (pn.nspname)::text AS function_schema,
        CASE
            WHEN (p.provariadic = (0)::oid) THEN false
            ELSE true
        END AS has_variadic,
        CASE
            WHEN ((p.provolatile)::text = ('i'::character(1))::text) THEN 'IMMUTABLE'::text
            WHEN ((p.provolatile)::text = ('s'::character(1))::text) THEN 'STABLE'::text
            WHEN ((p.provolatile)::text = ('v'::character(1))::text) THEN 'VOLATILE'::text
            ELSE NULL::text
        END AS function_type,
    pg_get_functiondef(p.oid) AS function_definition,
    (rtn.nspname)::text AS return_type_schema,
    (rt.typname)::text AS return_type_name,
        CASE
            WHEN ((rt.typtype)::text = ('b'::character(1))::text) THEN 'BASE'::text
            WHEN ((rt.typtype)::text = ('c'::character(1))::text) THEN 'COMPOSITE'::text
            WHEN ((rt.typtype)::text = ('d'::character(1))::text) THEN 'DOMAIN'::text
            WHEN ((rt.typtype)::text = ('e'::character(1))::text) THEN 'ENUM'::text
            WHEN ((rt.typtype)::text = ('r'::character(1))::text) THEN 'RANGE'::text
            WHEN ((rt.typtype)::text = ('p'::character(1))::text) THEN 'PSUEDO'::text
            ELSE NULL::text
        END AS return_type_type,
    p.proretset AS returns_set,
    ( SELECT COALESCE(json_agg(q.type_name), '[]'::json) AS "coalesce"
           FROM ( SELECT pt.typname AS type_name,
                    pat.ordinality
                   FROM (unnest(COALESCE(p.proallargtypes, (p.proargtypes)::oid[])) WITH ORDINALITY pat(oid, ordinality)
                     LEFT JOIN pg_type pt ON ((pt.oid = pat.oid)))
                  ORDER BY pat.ordinality) q) AS input_arg_types,
    to_json(COALESCE(p.proargnames, ARRAY[]::text[])) AS input_arg_names
   FROM (((pg_proc p
     JOIN pg_namespace pn ON ((pn.oid = p.pronamespace)))
     JOIN pg_type rt ON ((rt.oid = p.prorettype)))
     JOIN pg_namespace rtn ON ((rtn.oid = rt.typnamespace)))
  WHERE (((pn.nspname)::text !~~ 'pg_%'::text) AND ((pn.nspname)::text <> ALL (ARRAY['information_schema'::text, 'hdb_catalog'::text, 'hdb_views'::text])) AND (NOT (EXISTS ( SELECT 1
           FROM pg_aggregate
          WHERE ((pg_aggregate.aggfnoid)::oid = p.oid)))));


ALTER TABLE hdb_catalog.hdb_function_agg OWNER TO hasurauser;

--
-- Name: hdb_function_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_function_info_agg AS
 SELECT hdb_function_agg.function_name,
    hdb_function_agg.function_schema,
    row_to_json(( SELECT e.*::record AS e
           FROM ( SELECT hdb_function_agg.has_variadic,
                    hdb_function_agg.function_type,
                    hdb_function_agg.return_type_schema,
                    hdb_function_agg.return_type_name,
                    hdb_function_agg.return_type_type,
                    hdb_function_agg.returns_set,
                    hdb_function_agg.input_arg_types,
                    hdb_function_agg.input_arg_names,
                    (EXISTS ( SELECT 1
                           FROM information_schema.tables
                          WHERE (((tables.table_schema)::text = hdb_function_agg.return_type_schema) AND ((tables.table_name)::text = hdb_function_agg.return_type_name)))) AS returns_table) e)) AS function_info
   FROM hdb_catalog.hdb_function_agg;


ALTER TABLE hdb_catalog.hdb_function_info_agg OWNER TO hasurauser;

--
-- Name: hdb_permission; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_permission (
    table_schema text NOT NULL,
    table_name text NOT NULL,
    role_name text NOT NULL,
    perm_type text NOT NULL,
    perm_def jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false,
    CONSTRAINT hdb_permission_perm_type_check CHECK ((perm_type = ANY (ARRAY['insert'::text, 'select'::text, 'update'::text, 'delete'::text])))
);


ALTER TABLE hdb_catalog.hdb_permission OWNER TO hasurauser;

--
-- Name: hdb_permission_agg; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_permission_agg AS
 SELECT hdb_permission.table_schema,
    hdb_permission.table_name,
    hdb_permission.role_name,
    json_object_agg(hdb_permission.perm_type, hdb_permission.perm_def) AS permissions
   FROM hdb_catalog.hdb_permission
  GROUP BY hdb_permission.table_schema, hdb_permission.table_name, hdb_permission.role_name;


ALTER TABLE hdb_catalog.hdb_permission_agg OWNER TO hasurauser;

--
-- Name: hdb_primary_key; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_primary_key AS
 SELECT tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    json_agg(constraint_column_usage.column_name) AS columns
   FROM (information_schema.table_constraints tc
     JOIN ( SELECT x.tblschema AS table_schema,
            x.tblname AS table_name,
            x.colname AS column_name,
            x.cstrname AS constraint_name
           FROM ( SELECT DISTINCT nr.nspname,
                    r.relname,
                    a.attname,
                    c.conname
                   FROM pg_namespace nr,
                    pg_class r,
                    pg_attribute a,
                    pg_depend d,
                    pg_namespace nc,
                    pg_constraint c
                  WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (d.refclassid = ('pg_class'::regclass)::oid) AND (d.refobjid = r.oid) AND (d.refobjsubid = a.attnum) AND (d.classid = ('pg_constraint'::regclass)::oid) AND (d.objid = c.oid) AND (c.connamespace = nc.oid) AND (c.contype = 'c'::"char") AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (NOT a.attisdropped))
                UNION ALL
                 SELECT nr.nspname,
                    r.relname,
                    a.attname,
                    c.conname
                   FROM pg_namespace nr,
                    pg_class r,
                    pg_attribute a,
                    pg_namespace nc,
                    pg_constraint c
                  WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (nc.oid = c.connamespace) AND (r.oid =
                        CASE c.contype
                            WHEN 'f'::"char" THEN c.confrelid
                            ELSE c.conrelid
                        END) AND (a.attnum = ANY (
                        CASE c.contype
                            WHEN 'f'::"char" THEN c.confkey
                            ELSE c.conkey
                        END)) AND (NOT a.attisdropped) AND (c.contype = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"])) AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])))) x(tblschema, tblname, colname, cstrname)) constraint_column_usage ON ((((tc.constraint_name)::text = (constraint_column_usage.constraint_name)::text) AND ((tc.table_schema)::text = (constraint_column_usage.table_schema)::text) AND ((tc.table_name)::text = (constraint_column_usage.table_name)::text))))
  WHERE ((tc.constraint_type)::text = 'PRIMARY KEY'::text)
  GROUP BY tc.table_schema, tc.table_name, tc.constraint_name;


ALTER TABLE hdb_catalog.hdb_primary_key OWNER TO hasurauser;

--
-- Name: hdb_query_collection; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_query_collection (
    collection_name text NOT NULL,
    collection_defn jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_query_collection OWNER TO hasurauser;

--
-- Name: hdb_query_template; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_query_template (
    template_name text NOT NULL,
    template_defn jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_query_template OWNER TO hasurauser;

--
-- Name: hdb_relationship; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_relationship (
    table_schema text NOT NULL,
    table_name text NOT NULL,
    rel_name text NOT NULL,
    rel_type text,
    rel_def jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false,
    CONSTRAINT hdb_relationship_rel_type_check CHECK ((rel_type = ANY (ARRAY['object'::text, 'array'::text])))
);


ALTER TABLE hdb_catalog.hdb_relationship OWNER TO hasurauser;

--
-- Name: hdb_schema_update_event; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_schema_update_event (
    id bigint NOT NULL,
    instance_id uuid NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE hdb_catalog.hdb_schema_update_event OWNER TO hasurauser;

--
-- Name: hdb_schema_update_event_id_seq; Type: SEQUENCE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE SEQUENCE hdb_catalog.hdb_schema_update_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hdb_catalog.hdb_schema_update_event_id_seq OWNER TO hasurauser;

--
-- Name: hdb_schema_update_event_id_seq; Type: SEQUENCE OWNED BY; Schema: hdb_catalog; Owner: hasurauser
--

ALTER SEQUENCE hdb_catalog.hdb_schema_update_event_id_seq OWNED BY hdb_catalog.hdb_schema_update_event.id;


--
-- Name: hdb_table; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_table (
    table_schema text NOT NULL,
    table_name text NOT NULL,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_table OWNER TO hasurauser;

--
-- Name: hdb_table_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_table_info_agg AS
 SELECT tables.table_name,
    tables.table_schema,
    COALESCE(columns.columns, '[]'::json) AS columns,
    COALESCE(pk.columns, '[]'::json) AS primary_key_columns,
    COALESCE(constraints.constraints, '[]'::json) AS constraints,
    COALESCE(views.view_info, 'null'::json) AS view_info
   FROM ((((information_schema.tables tables
     LEFT JOIN ( SELECT c.table_name,
            c.table_schema,
            json_agg(json_build_object('name', c.column_name, 'type', c.udt_name, 'is_nullable', (c.is_nullable)::boolean)) AS columns
           FROM information_schema.columns c
          GROUP BY c.table_schema, c.table_name) columns ON ((((tables.table_schema)::text = (columns.table_schema)::text) AND ((tables.table_name)::text = (columns.table_name)::text))))
     LEFT JOIN ( SELECT hdb_primary_key.table_schema,
            hdb_primary_key.table_name,
            hdb_primary_key.constraint_name,
            hdb_primary_key.columns
           FROM hdb_catalog.hdb_primary_key) pk ON ((((tables.table_schema)::text = (pk.table_schema)::text) AND ((tables.table_name)::text = (pk.table_name)::text))))
     LEFT JOIN ( SELECT c.table_schema,
            c.table_name,
            json_agg(c.constraint_name) AS constraints
           FROM information_schema.table_constraints c
          WHERE (((c.constraint_type)::text = 'UNIQUE'::text) OR ((c.constraint_type)::text = 'PRIMARY KEY'::text))
          GROUP BY c.table_schema, c.table_name) constraints ON ((((tables.table_schema)::text = (constraints.table_schema)::text) AND ((tables.table_name)::text = (constraints.table_name)::text))))
     LEFT JOIN ( SELECT v.table_schema,
            v.table_name,
            json_build_object('is_updatable', ((v.is_updatable)::boolean OR (v.is_trigger_updatable)::boolean), 'is_deletable', ((v.is_updatable)::boolean OR (v.is_trigger_deletable)::boolean), 'is_insertable', ((v.is_insertable_into)::boolean OR (v.is_trigger_insertable_into)::boolean)) AS view_info
           FROM information_schema.views v) views ON ((((tables.table_schema)::text = (views.table_schema)::text) AND ((tables.table_name)::text = (views.table_name)::text))));


ALTER TABLE hdb_catalog.hdb_table_info_agg OWNER TO hasurauser;

--
-- Name: hdb_unique_constraint; Type: VIEW; Schema: hdb_catalog; Owner: hasurauser
--

CREATE VIEW hdb_catalog.hdb_unique_constraint AS
 SELECT tc.table_name,
    tc.constraint_schema AS table_schema,
    tc.constraint_name,
    json_agg(kcu.column_name) AS columns
   FROM (information_schema.table_constraints tc
     JOIN information_schema.key_column_usage kcu USING (constraint_schema, constraint_name))
  WHERE ((tc.constraint_type)::text = 'UNIQUE'::text)
  GROUP BY tc.table_name, tc.constraint_schema, tc.constraint_name;


ALTER TABLE hdb_catalog.hdb_unique_constraint OWNER TO hasurauser;

--
-- Name: hdb_version; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.hdb_version (
    hasura_uuid uuid DEFAULT public.gen_random_uuid() NOT NULL,
    version text NOT NULL,
    upgraded_on timestamp with time zone NOT NULL,
    cli_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    console_state jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE hdb_catalog.hdb_version OWNER TO hasurauser;

--
-- Name: remote_schemas; Type: TABLE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TABLE hdb_catalog.remote_schemas (
    id bigint NOT NULL,
    name text,
    definition json,
    comment text
);


ALTER TABLE hdb_catalog.remote_schemas OWNER TO hasurauser;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE; Schema: hdb_catalog; Owner: hasurauser
--

CREATE SEQUENCE hdb_catalog.remote_schemas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hdb_catalog.remote_schemas_id_seq OWNER TO hasurauser;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: hdb_catalog; Owner: hasurauser
--

ALTER SEQUENCE hdb_catalog.remote_schemas_id_seq OWNED BY hdb_catalog.remote_schemas.id;


--
-- Name: hdb_schema_update_event id; Type: DEFAULT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_schema_update_event ALTER COLUMN id SET DEFAULT nextval('hdb_catalog.hdb_schema_update_event_id_seq'::regclass);


--
-- Name: remote_schemas id; Type: DEFAULT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.remote_schemas ALTER COLUMN id SET DEFAULT nextval('hdb_catalog.remote_schemas_id_seq'::regclass);


--
-- Data for Name: event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.event_invocation_logs (id, event_id, status, request, response, created_at) FROM stdin;
\.


--
-- Data for Name: event_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.event_log (id, schema_name, table_name, trigger_name, payload, delivered, error, tries, created_at, locked, next_retry_at) FROM stdin;
\.


--
-- Data for Name: event_triggers; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.event_triggers (name, type, schema_name, table_name, configuration, comment) FROM stdin;
\.


--
-- Data for Name: hdb_allowlist; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_allowlist (collection_name) FROM stdin;
\.


--
-- Data for Name: hdb_function; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_function (function_schema, function_name, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_permission; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_permission (table_schema, table_name, role_name, perm_type, perm_def, comment, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_query_collection; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_query_collection (collection_name, collection_defn, comment, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_query_template; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_query_template (template_name, template_defn, comment, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_relationship; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_relationship (table_schema, table_name, rel_name, rel_type, rel_def, comment, is_system_defined) FROM stdin;
hdb_catalog	hdb_table	detail	object	{"manual_configuration": {"remote_table": {"name": "tables", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	primary_key	object	{"manual_configuration": {"remote_table": {"name": "hdb_primary_key", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	columns	array	{"manual_configuration": {"remote_table": {"name": "columns", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	foreign_key_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_foreign_key_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	relationships	array	{"manual_configuration": {"remote_table": {"name": "hdb_relationship", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_permission_agg", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	check_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_check_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	unique_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_unique_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	event_log	trigger	object	{"manual_configuration": {"remote_table": {"name": "event_triggers", "schema": "hdb_catalog"}, "column_mapping": {"trigger_name": "name"}}}	\N	t
hdb_catalog	event_triggers	events	array	{"manual_configuration": {"remote_table": {"name": "event_log", "schema": "hdb_catalog"}, "column_mapping": {"name": "trigger_name"}}}	\N	t
hdb_catalog	event_invocation_logs	event	object	{"foreign_key_constraint_on": "event_id"}	\N	t
hdb_catalog	event_log	logs	array	{"foreign_key_constraint_on": {"table": {"name": "event_invocation_logs", "schema": "hdb_catalog"}, "column": "event_id"}}	\N	t
hdb_catalog	hdb_function_agg	return_table_info	object	{"manual_configuration": {"remote_table": {"name": "hdb_table", "schema": "hdb_catalog"}, "column_mapping": {"return_type_name": "table_name", "return_type_schema": "table_schema"}}}	\N	t
public	mouse_gene	impc_embryo_viability_data	array	{"foreign_key_constraint_on": {"table": "impc_embryo_viability", "column": "mouse_gene_id"}}	\N	f
public	mouse_gene	impc_adult_viability_data	array	{"foreign_key_constraint_on": {"table": "impc_adult_viability", "column": "mouse_gene_id"}}	\N	f
public	mouse_gene	fusil_data	array	{"foreign_key_constraint_on": {"table": "fusil", "column": "mouse_gene_id"}}	\N	f
public	mouse_gene	mouse_gene_synonym_relations	array	{"foreign_key_constraint_on": {"table": "mouse_gene_synonym_relation", "column": "mouse_gene_id"}}	\N	f
public	mouse_gene	orthologs	array	{"foreign_key_constraint_on": {"table": "ortholog", "column": "mouse_gene_id"}}	\N	f
public	human_gene	hgnc_genes	array	{"foreign_key_constraint_on": {"table": "hgnc_gene", "column": "human_gene_id"}}	\N	f
public	human_gene	idg_data	array	{"foreign_key_constraint_on": {"table": "idg", "column": "human_gene_id"}}	\N	f
public	human_gene	clingen_data	array	{"foreign_key_constraint_on": {"table": "clingen", "column": "human_gene_id"}}	\N	f
public	human_gene	achilles_gene_effect_data	array	{"foreign_key_constraint_on": {"table": "achilles_gene_effect", "column": "human_gene_id"}}	\N	f
public	human_gene	gnomad_plof_data	array	{"foreign_key_constraint_on": {"table": "gnomad_plof", "column": "human_gene_id"}}	\N	f
public	human_gene	human_gene_synonym_relations	array	{"foreign_key_constraint_on": {"table": "human_gene_synonym_relation", "column": "human_gene_id"}}	\N	f
public	human_gene	orthologs	array	{"foreign_key_constraint_on": {"table": "ortholog", "column": "human_gene_id"}}	\N	f
public	ortholog	human_gene	object	{"foreign_key_constraint_on": "human_gene_id"}	\N	f
public	ortholog	mouse_gene	object	{"foreign_key_constraint_on": "mouse_gene_id"}	\N	f
public	mouse_gene_synonym	mouse_gene_synonym_relations	array	{"foreign_key_constraint_on": {"table": "mouse_gene_synonym_relation", "column": "mouse_gene_synonym_id"}}	\N	f
public	mouse_gene_synonym_relation	mouse_gene	object	{"foreign_key_constraint_on": "mouse_gene_id"}	\N	f
public	mouse_gene_synonym_relation	mouse_gene_synonym	object	{"foreign_key_constraint_on": "mouse_gene_synonym_id"}	\N	f
public	impc_embryo_viability	mouse_gene	object	{"foreign_key_constraint_on": "mouse_gene_id"}	\N	f
public	impc_adult_viability	mouse_gene	object	{"foreign_key_constraint_on": "mouse_gene_id"}	\N	f
public	idg	human_gene	object	{"foreign_key_constraint_on": "human_gene_id"}	\N	f
public	human_gene_synonym	human_gene_synonym_relations	array	{"foreign_key_constraint_on": {"table": "human_gene_synonym_relation", "column": "human_gene_synonym_id"}}	\N	f
public	human_gene_synonym_relation	human_gene	object	{"foreign_key_constraint_on": "human_gene_id"}	\N	f
public	human_gene_synonym_relation	human_gene_synonym	object	{"foreign_key_constraint_on": "human_gene_synonym_id"}	\N	f
public	hgnc_gene	human_gene	object	{"foreign_key_constraint_on": "human_gene_id"}	\N	f
public	gnomad_plof	human_gene	object	{"foreign_key_constraint_on": "human_gene_id"}	\N	f
public	fusil	mouse_gene	object	{"foreign_key_constraint_on": "mouse_gene_id"}	\N	f
public	clingen	human_gene	object	{"foreign_key_constraint_on": "human_gene_id"}	\N	f
public	achilles_gene_effect	human_gene	object	{"foreign_key_constraint_on": "human_gene_id"}	\N	f
\.


--
-- Data for Name: hdb_schema_update_event; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_schema_update_event (id, instance_id, occurred_at) FROM stdin;
1	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:24:51.046438+00
2	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:24:51.159521+00
3	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:24:57.200807+00
4	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:01.423533+00
5	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:01.533596+00
6	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:01.641269+00
7	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:01.739764+00
8	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:01.852141+00
9	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:01.861408+00
10	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:05.220179+00
11	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:10.384837+00
12	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:10.493343+00
13	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:10.59565+00
14	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:10.653793+00
15	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:10.762436+00
16	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:12.492264+00
17	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:13.815503+00
18	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:13.936454+00
19	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:14.045397+00
20	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:14.097224+00
21	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:14.30819+00
22	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:15.43065+00
23	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:17.410039+00
24	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:17.528345+00
25	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:17.6399+00
26	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:17.711711+00
27	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:17.822832+00
28	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:19.108869+00
29	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:21.415313+00
30	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:21.521959+00
31	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:21.625716+00
32	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:21.688829+00
33	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:21.806047+00
34	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:23.235075+00
35	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:24.596657+00
36	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:24.710295+00
37	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:24.823692+00
38	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:24.884017+00
39	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:25.013051+00
40	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:25.891659+00
41	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:27.660421+00
42	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:27.780848+00
43	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:27.897817+00
44	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:27.959489+00
45	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:28.079831+00
46	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:29.237069+00
47	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:31.097315+00
48	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:31.20976+00
49	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:31.312645+00
50	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:31.368816+00
51	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:31.482549+00
52	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:32.877674+00
53	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:34.449001+00
54	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:34.571945+00
55	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:34.682441+00
56	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:34.743457+00
57	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:34.861795+00
58	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:36.141801+00
59	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:38.14099+00
60	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:38.25993+00
61	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:38.376419+00
62	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:38.453673+00
63	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:38.567561+00
64	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:39.912432+00
65	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:42.539412+00
66	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:42.648835+00
67	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:42.751493+00
68	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:42.821893+00
69	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:42.930319+00
70	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:44.166664+00
71	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:48.778859+00
72	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:48.923006+00
73	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:49.054198+00
74	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:49.143989+00
75	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:49.270637+00
76	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:50.934519+00
77	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:58.473289+00
78	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:58.598191+00
79	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:58.709187+00
80	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:58.78006+00
81	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:25:58.885004+00
82	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:00.762865+00
83	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:03.051692+00
84	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:03.164573+00
85	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:03.285588+00
86	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:03.363608+00
87	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:03.469597+00
88	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:04.948607+00
89	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:06.281128+00
90	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:06.406675+00
91	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:06.520586+00
92	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:06.596978+00
93	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:06.705836+00
94	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:31.866429+00
95	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:31.931784+00
96	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:42.832708+00
97	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:42.898678+00
98	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:49.307721+00
99	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:49.418084+00
100	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:53.999591+00
101	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:54.06736+00
102	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:57.238046+00
103	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:26:57.301177+00
104	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:17.685591+00
105	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:17.739954+00
106	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:25.515392+00
107	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:25.574743+00
108	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:32.844498+00
109	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:32.906116+00
110	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:38.586053+00
111	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:38.639125+00
112	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:44.007259+00
113	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:44.058521+00
114	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:48.922815+00
115	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:48.990137+00
116	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:52.554905+00
117	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:27:52.608357+00
118	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:08.739653+00
119	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:08.799129+00
120	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:11.645259+00
121	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:11.698216+00
122	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:22.583749+00
123	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:22.639067+00
124	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:29.334712+00
125	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:29.388297+00
126	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:33.055114+00
127	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:33.106582+00
128	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:45.120601+00
129	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:45.190512+00
130	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:51.864496+00
131	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:28:51.927263+00
132	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:02.390331+00
133	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:02.448811+00
134	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:10.302562+00
135	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:10.357478+00
136	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:15.894375+00
137	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:15.951661+00
138	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:18.302527+00
139	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:18.382987+00
140	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:28.90991+00
141	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:28.990138+00
142	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:36.558734+00
143	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:36.644429+00
146	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:51.662642+00
147	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:51.716655+00
144	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:45.437982+00
145	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:45.48944+00
148	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:56.79789+00
149	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:29:56.851078+00
150	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:31:29.041898+00
151	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:31:29.152567+00
152	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:32:39.607616+00
153	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:32:39.732257+00
154	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:33:25.903214+00
155	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:33:26.03727+00
156	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:33:40.994328+00
157	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:33:41.117412+00
158	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:33:53.64687+00
159	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:33:53.764682+00
160	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:10.745496+00
161	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:10.872959+00
162	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:23.409685+00
163	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:23.530133+00
164	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:38.683718+00
165	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:38.806424+00
166	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:54.222926+00
167	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:34:54.348073+00
168	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:06.204462+00
169	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:06.336715+00
170	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:24.743412+00
171	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:24.86408+00
172	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:45.746992+00
173	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:45.878499+00
174	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:56.313771+00
175	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:35:56.43976+00
176	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:12.122683+00
177	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:12.248965+00
178	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:25.249558+00
179	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:25.375285+00
180	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:36.024336+00
181	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:36.145874+00
182	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:50.429448+00
183	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:36:50.552214+00
184	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:37:01.857725+00
185	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:37:01.972465+00
186	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:38:06.588855+00
187	fdae4432-9dbe-48b1-a16f-2063aad4065d	2020-06-02 16:38:18.555384+00
\.


--
-- Data for Name: hdb_table; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_table (table_schema, table_name, is_system_defined) FROM stdin;
hdb_catalog	hdb_table	t
information_schema	tables	t
information_schema	schemata	t
information_schema	views	t
hdb_catalog	hdb_primary_key	t
information_schema	columns	t
hdb_catalog	hdb_foreign_key_constraint	t
hdb_catalog	hdb_relationship	t
hdb_catalog	hdb_permission_agg	t
hdb_catalog	hdb_check_constraint	t
hdb_catalog	hdb_unique_constraint	t
hdb_catalog	hdb_query_template	t
hdb_catalog	event_triggers	t
hdb_catalog	event_log	t
hdb_catalog	event_invocation_logs	t
hdb_catalog	hdb_function_agg	t
hdb_catalog	hdb_function	t
hdb_catalog	remote_schemas	t
hdb_catalog	hdb_version	t
hdb_catalog	hdb_query_collection	t
hdb_catalog	hdb_allowlist	t
public	achilles_gene_effect	f
public	clingen	f
public	fusil	f
public	gnomad_plof	f
public	hgnc_gene	f
public	human_gene	f
public	human_gene_synonym	f
public	human_gene_synonym_relation	f
public	idg	f
public	impc_adult_viability	f
public	impc_embryo_viability	f
public	mouse_gene	f
public	mouse_gene_synonym	f
public	mouse_gene_synonym_relation	f
public	ortholog	f
\.


--
-- Data for Name: hdb_version; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.hdb_version (hasura_uuid, version, upgraded_on, cli_state, console_state) FROM stdin;
8b4703a5-2d78-4529-817e-082ac507c2ba	17	2020-06-02 16:21:26.736838+00	{}	{"telemetryNotificationShown": true}
\.


--
-- Data for Name: remote_schemas; Type: TABLE DATA; Schema: hdb_catalog; Owner: hasurauser
--

COPY hdb_catalog.remote_schemas (id, name, definition, comment) FROM stdin;
\.


--
-- Name: hdb_schema_update_event_id_seq; Type: SEQUENCE SET; Schema: hdb_catalog; Owner: hasurauser
--

SELECT pg_catalog.setval('hdb_catalog.hdb_schema_update_event_id_seq', 187, true);


--
-- Name: remote_schemas_id_seq; Type: SEQUENCE SET; Schema: hdb_catalog; Owner: hasurauser
--

SELECT pg_catalog.setval('hdb_catalog.remote_schemas_id_seq', 1, false);


--
-- Name: event_invocation_logs event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_pkey PRIMARY KEY (id);


--
-- Name: event_log event_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.event_log
    ADD CONSTRAINT event_log_pkey PRIMARY KEY (id);


--
-- Name: event_triggers event_triggers_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.event_triggers
    ADD CONSTRAINT event_triggers_pkey PRIMARY KEY (name);


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_allowlist
    ADD CONSTRAINT hdb_allowlist_collection_name_key UNIQUE (collection_name);


--
-- Name: hdb_function hdb_function_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_function
    ADD CONSTRAINT hdb_function_pkey PRIMARY KEY (function_schema, function_name);


--
-- Name: hdb_permission hdb_permission_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_permission
    ADD CONSTRAINT hdb_permission_pkey PRIMARY KEY (table_schema, table_name, role_name, perm_type);


--
-- Name: hdb_query_collection hdb_query_collection_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_query_collection
    ADD CONSTRAINT hdb_query_collection_pkey PRIMARY KEY (collection_name);


--
-- Name: hdb_query_template hdb_query_template_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_query_template
    ADD CONSTRAINT hdb_query_template_pkey PRIMARY KEY (template_name);


--
-- Name: hdb_relationship hdb_relationship_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_relationship
    ADD CONSTRAINT hdb_relationship_pkey PRIMARY KEY (table_schema, table_name, rel_name);


--
-- Name: hdb_schema_update_event hdb_schema_update_event_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_schema_update_event
    ADD CONSTRAINT hdb_schema_update_event_pkey PRIMARY KEY (id);


--
-- Name: hdb_table hdb_table_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_table
    ADD CONSTRAINT hdb_table_pkey PRIMARY KEY (table_schema, table_name);


--
-- Name: hdb_version hdb_version_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_version
    ADD CONSTRAINT hdb_version_pkey PRIMARY KEY (hasura_uuid);


--
-- Name: remote_schemas remote_schemas_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.remote_schemas
    ADD CONSTRAINT remote_schemas_name_key UNIQUE (name);


--
-- Name: remote_schemas remote_schemas_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.remote_schemas
    ADD CONSTRAINT remote_schemas_pkey PRIMARY KEY (id);


--
-- Name: event_invocation_logs_event_id_idx; Type: INDEX; Schema: hdb_catalog; Owner: hasurauser
--

CREATE INDEX event_invocation_logs_event_id_idx ON hdb_catalog.event_invocation_logs USING btree (event_id);


--
-- Name: event_log_trigger_name_idx; Type: INDEX; Schema: hdb_catalog; Owner: hasurauser
--

CREATE INDEX event_log_trigger_name_idx ON hdb_catalog.event_log USING btree (trigger_name);


--
-- Name: hdb_version_one_row; Type: INDEX; Schema: hdb_catalog; Owner: hasurauser
--

CREATE UNIQUE INDEX hdb_version_one_row ON hdb_catalog.hdb_version USING btree (((version IS NOT NULL)));


--
-- Name: hdb_schema_update_event hdb_schema_update_event_notifier; Type: TRIGGER; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TRIGGER hdb_schema_update_event_notifier AFTER INSERT ON hdb_catalog.hdb_schema_update_event FOR EACH ROW EXECUTE PROCEDURE hdb_catalog.hdb_schema_update_event_notifier();


--
-- Name: hdb_table hdb_table_oid_check; Type: TRIGGER; Schema: hdb_catalog; Owner: hasurauser
--

CREATE TRIGGER hdb_table_oid_check BEFORE INSERT OR UPDATE ON hdb_catalog.hdb_table FOR EACH ROW EXECUTE PROCEDURE hdb_catalog.hdb_table_oid_check();


--
-- Name: event_invocation_logs event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.event_log(id);


--
-- Name: event_triggers event_triggers_schema_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.event_triggers
    ADD CONSTRAINT event_triggers_schema_name_fkey FOREIGN KEY (schema_name, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_allowlist
    ADD CONSTRAINT hdb_allowlist_collection_name_fkey FOREIGN KEY (collection_name) REFERENCES hdb_catalog.hdb_query_collection(collection_name);


--
-- Name: hdb_permission hdb_permission_table_schema_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_permission
    ADD CONSTRAINT hdb_permission_table_schema_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_relationship hdb_relationship_table_schema_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: hasurauser
--

ALTER TABLE ONLY hdb_catalog.hdb_relationship
    ADD CONSTRAINT hdb_relationship_table_schema_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- PostgreSQL database dump complete
--

-- 
-- Chnage the access to hdb_catalog tables
-- 

REVOKE ALL ON hdb_catalog.hdb_table FROM hasurauser;
GRANT SELECT ON hdb_catalog.hdb_table TO hasurauser;


REVOKE ALL ON hdb_catalog.hdb_relationship FROM hasurauser;
GRANT SELECT ON hdb_catalog.hdb_relationship TO hasurauser;


REVOKE ALL ON hdb_catalog.hdb_permission FROM hasurauser;
GRANT SELECT ON hdb_catalog.hdb_permission TO hasurauser;