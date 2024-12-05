--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

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
-- Name: flag_frequent_transactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.flag_frequent_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT COUNT(*) 
        FROM transactions 
        WHERE user_id = NEW.user_id 
        AND transaction_date > NOW() - INTERVAL '1 hour') > 
        (SELECT threshold FROM compliance_rules WHERE rule_name = 'Frequent Transactions') THEN
        INSERT INTO risk_alerts (transaction_id, alert_message)
        VALUES (NEW.transaction_id, 'Frequent transactions flagged for review.');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.flag_frequent_transactions() OWNER TO postgres;

--
-- Name: flag_high_value_transactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.flag_high_value_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if the transaction amount exceeds the threshold
    IF NEW.amount > (SELECT threshold FROM compliance_rules WHERE rule_name = 'High-Value Transaction') THEN
        -- Insert a record into risk_alerts table if the transaction exceeds the threshold
        INSERT INTO risk_alerts (transaction_id, alert_message)
        VALUES (NEW.transaction_id, 'High-value transaction flagged for review.');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.flag_high_value_transactions() OWNER TO postgres;

--
-- Name: log_action(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_action() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO action_logs (action_type, table_name, details)
    VALUES (TG_OP, TG_TABLE_NAME, ROW(NEW.*)::TEXT);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_action() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.action_logs (
    log_id integer NOT NULL,
    action_type character varying(50),
    table_name character varying(50),
    action_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    details text
);


ALTER TABLE public.action_logs OWNER TO postgres;

--
-- Name: action_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.action_logs_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_logs_log_id_seq OWNER TO postgres;

--
-- Name: action_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.action_logs_log_id_seq OWNED BY public.action_logs.log_id;


--
-- Name: compliance_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compliance_rules (
    rule_id integer NOT NULL,
    rule_name character varying(100) NOT NULL,
    threshold numeric(15,2) NOT NULL,
    description text
);


ALTER TABLE public.compliance_rules OWNER TO postgres;

--
-- Name: compliance_rules_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.compliance_rules_rule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.compliance_rules_rule_id_seq OWNER TO postgres;

--
-- Name: compliance_rules_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.compliance_rules_rule_id_seq OWNED BY public.compliance_rules.rule_id;


--
-- Name: risk_alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.risk_alerts (
    alert_id integer NOT NULL,
    transaction_id integer,
    alert_message text NOT NULL,
    alert_created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.risk_alerts OWNER TO postgres;

--
-- Name: risk_alerts_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.risk_alerts_alert_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.risk_alerts_alert_id_seq OWNER TO postgres;

--
-- Name: risk_alerts_alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.risk_alerts_alert_id_seq OWNED BY public.risk_alerts.alert_id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    transaction_id integer NOT NULL,
    user_id integer,
    amount numeric(15,2) NOT NULL,
    transaction_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(50) DEFAULT 'Pending'::character varying
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_transaction_id_seq OWNER TO postgres;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    country character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: action_logs log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.action_logs ALTER COLUMN log_id SET DEFAULT nextval('public.action_logs_log_id_seq'::regclass);


--
-- Name: compliance_rules rule_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compliance_rules ALTER COLUMN rule_id SET DEFAULT nextval('public.compliance_rules_rule_id_seq'::regclass);


--
-- Name: risk_alerts alert_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_alerts ALTER COLUMN alert_id SET DEFAULT nextval('public.risk_alerts_alert_id_seq'::regclass);


--
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: action_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.action_logs (log_id, action_type, table_name, action_time, details) FROM stdin;
1	UPDATE	transactions	2024-12-05 18:59:58.190731	(1,1,5000.00,"2024-12-05 18:59:58.190731",Completed)
2	UPDATE	transactions	2024-12-05 18:59:58.190731	(4,1,15000.00,"2024-12-05 18:59:58.190731",Completed)
3	UPDATE	transactions	2024-12-05 18:59:58.190731	(9,1,20000.00,"2024-12-05 18:59:58.190731",Completed)
4	UPDATE	transactions	2024-12-05 18:59:58.190731	(11,1,500.00,"2024-12-05 18:59:58.190731",Completed)
5	UPDATE	transactions	2024-12-05 18:59:58.190731	(12,1,600.00,"2024-12-05 18:59:58.190731",Completed)
6	UPDATE	transactions	2024-12-05 18:59:58.190731	(13,1,700.00,"2024-12-05 18:59:58.190731",Completed)
7	UPDATE	transactions	2024-12-05 18:59:58.190731	(14,1,500.00,"2024-12-05 18:59:58.190731",Completed)
8	UPDATE	transactions	2024-12-05 18:59:58.190731	(15,1,600.00,"2024-12-05 18:59:58.190731",Completed)
9	UPDATE	transactions	2024-12-05 18:59:58.190731	(16,1,700.00,"2024-12-05 18:59:58.190731",Completed)
10	DELETE	transactions	2024-12-05 19:00:35.838369	(,,,,)
11	DELETE	transactions	2024-12-05 19:00:35.838369	(,,,,)
12	DELETE	transactions	2024-12-05 19:00:35.838369	(,,,,)
13	UPDATE	transactions	2024-12-05 19:04:51.208453	(1,1,2500.00,"2024-12-05 18:59:58.190731",Completed)
14	DELETE	transactions	2024-12-05 19:05:07.712396	(,,,,)
\.


--
-- Data for Name: compliance_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compliance_rules (rule_id, rule_name, threshold, description) FROM stdin;
1	High-Value Transaction	10000.00	Flag transactions over $10,000 for review
2	Frequent Transactions	3.00	Flag users with more than 3 transactions in an hour
\.


--
-- Data for Name: risk_alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.risk_alerts (alert_id, transaction_id, alert_message, alert_created_at) FROM stdin;
3	9	High-value transaction flagged for review.	2024-12-04 23:12:09.860185
4	17	Frequent transactions flagged for review.	2024-12-05 19:03:25.458242
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (transaction_id, user_id, amount, transaction_date, status) FROM stdin;
3	3	3000.00	2024-12-01 12:00:00	Pending
5	2	500.00	2024-12-02 11:00:00	Pending
10	2	5000.00	2024-12-04 11:00:00	Completed
4	1	15000.00	2024-12-05 18:59:58.190731	Completed
9	1	20000.00	2024-12-05 18:59:58.190731	Completed
14	1	500.00	2024-12-05 18:59:58.190731	Completed
15	1	600.00	2024-12-05 18:59:58.190731	Completed
16	1	700.00	2024-12-05 18:59:58.190731	Completed
17	1	800.00	2024-12-05 19:03:25.458242	Completed
1	1	2500.00	2024-12-05 18:59:58.190731	Completed
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, first_name, last_name, email, country, created_at) FROM stdin;
1	John	Doe	john.doe@example.com	USA	2024-12-04 22:22:34.783473
2	Jane	Smith	jane.smith@example.com	Canada	2024-12-04 22:22:34.783473
3	George	Brown	george.brown@example.com	UK	2024-12-04 22:22:34.783473
\.


--
-- Name: action_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.action_logs_log_id_seq', 14, true);


--
-- Name: compliance_rules_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compliance_rules_rule_id_seq', 2, true);


--
-- Name: risk_alerts_alert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.risk_alerts_alert_id_seq', 4, true);


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transactions_transaction_id_seq', 17, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 3, true);


--
-- Name: action_logs action_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.action_logs
    ADD CONSTRAINT action_logs_pkey PRIMARY KEY (log_id);


--
-- Name: compliance_rules compliance_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT compliance_rules_pkey PRIMARY KEY (rule_id);


--
-- Name: risk_alerts risk_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_alerts
    ADD CONSTRAINT risk_alerts_pkey PRIMARY KEY (alert_id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: idx_alert_message; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_message ON public.risk_alerts USING btree (alert_message);


--
-- Name: idx_transaction_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaction_date ON public.transactions USING btree (transaction_date);


--
-- Name: idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_id ON public.transactions USING btree (user_id);


--
-- Name: idx_user_id_transaction_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_id_transaction_date ON public.transactions USING btree (user_id, transaction_date);


--
-- Name: transactions check_frequent_transactions; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_frequent_transactions AFTER INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.flag_frequent_transactions();


--
-- Name: transactions check_high_value_transaction; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_high_value_transaction AFTER INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.flag_high_value_transactions();


--
-- Name: transactions log_transaction_deletes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_transaction_deletes AFTER DELETE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.log_action();


--
-- Name: transactions log_transaction_updates; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_transaction_updates AFTER UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.log_action();


--
-- Name: risk_alerts fk_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_alerts
    ADD CONSTRAINT fk_transaction_id FOREIGN KEY (transaction_id) REFERENCES public.transactions(transaction_id) ON DELETE CASCADE;


--
-- Name: risk_alerts risk_alerts_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_alerts
    ADD CONSTRAINT risk_alerts_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(transaction_id);


--
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- PostgreSQL database dump complete
--

