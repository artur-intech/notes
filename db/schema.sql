--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Ubuntu 16.1-1.pgdg22.04+1)
-- Dumped by pg_dump version 16.1 (Ubuntu 16.1-1.pgdg22.04+1)

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
-- Name: string_nonempty(text); Type: FUNCTION; Schema: public; Owner: notes_development
--

CREATE FUNCTION public.string_nonempty(string text) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    RETURN ((string = ''::text) IS NOT TRUE);


ALTER FUNCTION public.string_nonempty(string text) OWNER TO notes_development;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: applied_migrations; Type: TABLE; Schema: public; Owner: notes_development
--

CREATE TABLE public.applied_migrations (
    id character varying(255) NOT NULL
);


ALTER TABLE public.applied_migrations OWNER TO notes_development;

--
-- Name: notes; Type: TABLE; Schema: public; Owner: notes_development
--

CREATE TABLE public.notes (
    id integer NOT NULL,
    text text,
    "position" integer NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    CONSTRAINT nonempty_text CHECK (public.string_nonempty(text))
);


ALTER TABLE public.notes OWNER TO notes_development;

--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: notes_development
--

ALTER TABLE public.notes ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: notes_development
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying NOT NULL,
    encrypted_password character varying NOT NULL
);


ALTER TABLE public.users OWNER TO notes_development;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: notes_development
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: applied_migrations; Type: TABLE DATA; Schema: public; Owner: notes_development
--

COPY public.applied_migrations (id) FROM stdin;
1712914287_add_string_nonempty_function
1713181142_add_nonempty_note_text_constraint
1714298297_change_notes_updated_at_to_timestamp_with_time_zone
\.


--
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: notes_development
--

SELECT pg_catalog.setval('public.notes_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: notes_development
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: applied_migrations applied_migrations_id_key; Type: CONSTRAINT; Schema: public; Owner: notes_development
--

ALTER TABLE ONLY public.applied_migrations
    ADD CONSTRAINT applied_migrations_id_key UNIQUE (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: notes_development
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: users users_email_pkey; Type: CONSTRAINT; Schema: public; Owner: notes_development
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_pkey UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: notes_development
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: notes notes_users_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: notes_development
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_users_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--
