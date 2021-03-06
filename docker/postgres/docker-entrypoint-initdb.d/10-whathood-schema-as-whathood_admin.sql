-- run all commands in here as whathood_admin

--
-- PostgreSQL database dump
--

\connect whathood;

SET ROLE whathood_admin;

-- SET search_path = whathood, public, pg_catalog;

--
-- Name: polygon_counts_result; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE polygon_counts_result AS (
	point_as_text text,
	test_neighborhood_name text,
	point geometry,
	neighborhood_names text,
	num_in_neighborhood integer,
	total_user_polygons integer,
	strength_of_identity double precision,
	dominant_neighborhood_id integer
);

--
-- Name: neighborhood_counts_by_point_result; Type: TYPE; Schema: whathood; Owner: -
--

CREATE TYPE neighborhood_counts_by_point_result AS (
	neighborhood_name character varying(255),
	neighborhood_id integer,
	total_user_polygons bigint
);

--
-- Name: delete_user_polygon(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_user_polygon(_up_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

  IF ( SELECT 1 FROM user_polygon WHERE id = _up_id LIMIT 1 ) THEN
    DELETE FROM trans_tp_up WHERE user_polygon_id = _up_id;
    DELETE FROM trans_np_up WHERE up_id = _up_id;
    DELETE FROM user_polygon WHERE id = _up_id;

    RAISE NOTICE 'you must re-run the process to build neighborhood_polygons';
  ELSE
    RAISE EXCEPTION 'user_polygon with id % does not exist',test_up_id;
  END IF;

END;
$$;

--
-- Name: create_contentious_points(integer); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION create_contentious_points(_create_event_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO contentious_point( create_event_id, test_point_id, point, strength_of_identity ) (
    SELECT DISTINCT
      _create_event_id,
      test_point.id,
      test_point.point,
      a.strength_of_identity
    FROM
      neighborhood_point_strength_of_identity a,
      neighborhood_point_strength_of_identity b,
      test_point

    WHERE
      test_point.id = a.test_point_id
      AND  a.id <> b.id
      AND a.test_point_id = b.test_point_id
      AND a.strength_of_identity = b.strength_of_identity
      AND a.create_event_id = _create_event_id
      AND a.create_event_id = b.create_event_id
    GROUP BY test_point.id,a.strength_of_identity,test_point.point
  );
END;
$$;


--
-- Name: gather_test_point_counts(geometry[], integer); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION gather_test_point_counts(test_points geometry[], _neighborhood_id integer) RETURNS SETOF polygon_counts_result
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _test_point geometry;
    _r polygon_counts_result%rowtype;
    _polygon_count_result_array polygon_counts_result[];
    _polygon_counts_result polygon_counts_result;
  BEGIN

    FOREACH _test_point IN ARRAY test_points LOOP
      SELECT * INTO _r
      FROM whathood.polygon_counts(_test_point,_neighborhood_id);
      RETURN NEXT _r;
   END LOOP;
  END;
$$;


--
-- Name: get_dominant_neighborhood(geometry); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION get_dominant_neighborhood(_test_point geometry) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  _total integer;
  _max_user_polygons integer;
  _neighborhood_id integer;
BEGIN
  SELECT MAX(total_user_polygons) INTO _max_user_polygons
  FROM whathood.neighborhood_counts_by_point(_test_point);

  SELECT COUNT(*) INTO _total
  FROM whathood.neighborhood_counts_by_point(_test_point)
  WHERE total_user_polygons = _max_user_polygons;

  IF _total = 0 THEN
    RETURN 0;
  ELSIF _total = 1 THEN
    SELECT a.neighborhood_id INTO _neighborhood_id FROM whathood.neighborhood_counts_by_point(_test_point) a;
    RETURN _neighborhood_id;
  ELSE
    RETURN -1;
  END IF;
END;
$$;


--
-- Name: latest_neighborhoods_geojson(integer); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION latest_neighborhoods_geojson(test_region_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
  geojson varchar;
BEGIN
  SELECT row_to_json( fc ) INTO geojson
    FROM ( SELECT 'FeatureCollection' as type, array_to_json(array_agg(f)) as features
    FROM( SELECT 'Feature' as type
      , ST_AsGeoJSON( slnp.polygon)::json AS geometry
      , row_to_json(
        (SELECT l FROM ( SELECT name,slnp.id) AS l)
      ) AS properties
  FROM latest_neighborhoods slnp
    INNER JOIN neighborhood
      ON slnp.neighborhood_id = neighborhood.id ) as f ) as fc;
  RETURN geojson;
END;
$$;


--
-- Name: makegrid_2d(geometry, numeric); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION makegrid_2d(bound_polygon geometry, grid_step numeric) RETURNS geometry[]
    LANGUAGE plpgsql
    AS $_$
DECLARE
  BoundM geometry; --Bound polygon transformed to metric projection (with metric_srid SRID)
  Xmin DOUBLE PRECISION;
  Xmax DOUBLE PRECISION;
  Ymax DOUBLE PRECISION;
  X DOUBLE PRECISION;
  Y DOUBLE PRECISION;
  point geometry;
  points geometry[];
  i INTEGER;
  j INTEGER;
  count INTEGER = 0;
BEGIN
  BoundM := $1;
  Xmin := ST_XMin(BoundM);
  Xmax := ST_XMax(BoundM);
  Ymax := ST_YMax(BoundM);

  Y := ST_YMin(BoundM); --current sector's corner coordinate
  <<yloop>>
  LOOP
    IF (Y > Ymax) THEN  --Better if generating polygons exceeds bound for one step. You always can crop the result. But if not you may get not quite correct data for outbound polygons (if you calculate frequency per a sector  e.g.)
        EXIT;
    END IF;

    X := Xmin;
    <<xloop>>
    LOOP
      IF (X > Xmax) THEN
          EXIT;
      END IF;
      point := ST_SetSRID(ST_Point(X,Y), 4326);

      -- we only want points that are inside the bound_polygon
      IF( SELECT ST_Contains( bound_polygon,point) = true ) THEN
        points := array_append(points,point);
        count := count + 1;
      END IF;
      X := X + grid_step;
    END LOOP xloop;
    Y := Y + grid_step;
  END LOOP yloop;

  RETURN points;
END;
$_$;


--
-- Name: neighborhood_counts_by_point(geometry); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION neighborhood_counts_by_point(_test_point geometry) RETURNS SETOF neighborhood_counts_by_point_result
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY SELECT
    neighborhood_name,
    neighborhood_id,
    COUNT(*) total_user_polygons
  FROM whathood.user_polygon_test_point c1
  WHERE
    ST_Contains(c1.polygon,_test_point)
  GROUP BY
    neighborhood_name,
    neighborhood_id
  ORDER BY total_user_polygons DESC;
END;
$$;


--
-- Name: neighborhood_point_geometry(integer, geometry, numeric); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION neighborhood_point_geometry(_neighborhood_id integer, _user_polygon_bound geometry, _grid_resolution numeric) RETURNS geometry
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  RETURN ST_Collect(point) FROM whathood.neighborhood_point_info(_neighborhood_id,_user_polygon_bound,_grid_resolution); 
END;
$$;


--
-- Name: neighborhood_point_info(integer, geometry, numeric); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION neighborhood_point_info(_neighborhood_id integer, _user_polygon_bound geometry, _grid_resolution numeric) RETURNS SETOF polygon_counts_result
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  RETURN QUERY SELECT
    (whathood.gather_test_point_counts(
      whathood.makegrid_2d(
        _user_polygon_bound,
        _grid_resolution
      ),
      _neighborhood_id
    )).*
  ;
END;
$$;


--
-- Name: polygon_counts(geometry, integer); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION polygon_counts(_test_point geometry, _neighborhood_id integer) RETURNS polygon_counts_result
    LANGUAGE plpgsql
    AS $$
DECLARE
  _point_as_text text;
  _test_neighborhood_name text;
  _ret_val polygon_counts_result%rowtype;
  _neighborhood_name_arr text[];
  _neighborhood_names text;
  _num_in_neighborhood integer;
  _total_user_polygons integer;
  _dominant_neighborhood_id integer;
BEGIN

  SELECT name INTO _ret_val.test_neighborhood_name FROM neighborhood WHERE id = _neighborhood_id;

  --
  --
  --
  SELECT COUNT(*) INTO _num_in_neighborhood
  FROM user_polygon up
  WHERE
    neighborhood_id = _neighborhood_id
    AND ST_Contains(up.polygon,_test_point) = 'true';

  --
  -- get the names of the neighborhoods this test point is in
  --
  SELECT
    array_agg(neighborhood_name) INTO _neighborhood_name_arr
  FROM
    whathood.user_polygon_test_point
  WHERE
    ST_Contains(polygon,_test_point);

  --
  --
  --
  SELECT COUNT(*) INTO _total_user_polygons
  FROM user_polygon up
  WHERE
    ST_Contains(up.polygon,_test_point) = 'true';

  --
  --
  --
  SELECT ST_AsText(_test_point) INTO _point_as_text;

  --
  --
  --
  SELECT whathood.get_dominant_neighborhood(_test_point)
  INTO _dominant_neighborhood_id;

  IF _total_user_polygons = 0 THEN
    _ret_val.strength_of_identity := 0;
  ELSE
    _ret_val.strength_of_identity := cast(_num_in_neighborhood as double precision)/cast(_total_user_polygons as double precision);
  END IF;

  _ret_val.point_as_text        := _point_as_text;
  _ret_val.point                := _test_point;
  _ret_val.num_in_neighborhood  := _num_in_neighborhood;
  _ret_val.total_user_polygons  := _total_user_polygons;
  _ret_val.neighborhood_names   := array_to_string(_neighborhood_name_arr,';');
  _ret_val.dominant_neighborhood_id := _dominant_neighborhood_id;

  RETURN _ret_val;
END;
$$;


--
-- Name: post_create_neighborhood_border(geometry); Type: FUNCTION; Schema: whathood; Owner: -
--

CREATE FUNCTION post_create_neighborhood_border(_collected_points geometry) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN


END;
$$;

--
-- Name: heatmap_point; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE heatmap_point (
    id integer NOT NULL,
    neighborhood_id integer NOT NULL,
    point geometry NOT NULL,
    percentage double precision NOT NULL,
    created_at timestamp(0) with time zone NOT NULL
);


--
-- Name: COLUMN heatmap_point.point; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN heatmap_point.point IS '(DC2Type:geometry)';


--
-- Name: heatmap_point_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE heatmap_point_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neighborhood_polygon; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE neighborhood_polygon (
    id integer NOT NULL,
    neighborhood_id integer NOT NULL,
    polygon geometry NOT NULL,
    created_at timestamp(0) with time zone NOT NULL,
    grid_resolution double precision,
    target_precision double precision
);


--
-- Name: COLUMN neighborhood_polygon.polygon; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN neighborhood_polygon.polygon IS '(DC2Type:geometry)';


--
-- Name: latest_neighborhoods; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW latest_neighborhoods AS
 SELECT np.id,
    np.neighborhood_id,
    np.polygon,
    np.created_at,
    np.grid_resolution,
    np.target_precision
   FROM neighborhood_polygon np
  WHERE (np.id IN ( SELECT max(neighborhood_polygon.id) AS id_max
           FROM neighborhood_polygon
          GROUP BY neighborhood_polygon.neighborhood_id));


--
-- Name: neighborhood; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE neighborhood (
    id integer NOT NULL,
    region_id integer NOT NULL,
    name character varying(255) NOT NULL,
    no_build_border boolean,
    date_time_added character varying(255) NOT NULL
);


--
-- Name: neighborhood_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE neighborhood_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neighborhood_polygon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE neighborhood_polygon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queue_default; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE queue_default (
    id integer NOT NULL,
    queue character varying(64) NOT NULL,
    data text NOT NULL,
    status smallint NOT NULL,
    created timestamp(0) without time zone NOT NULL,
    scheduled timestamp(0) without time zone NOT NULL,
    executed timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    finished timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    message text,
    trace text
);


--
-- Name: queue_default_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE queue_default_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queue_default_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE queue_default_id_seq OWNED BY queue_default.id;


--
-- Name: region; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE region (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


--
-- Name: region_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE role (
    id integer NOT NULL,
    parent_id integer,
    roleid character varying(255) DEFAULT NULL::character varying
);


--
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: up_np; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE up_np (
    up_id integer NOT NULL,
    np_id integer NOT NULL
);


--
-- Name: user_polygon; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_polygon (
    id integer NOT NULL,
    neighborhood_id integer NOT NULL,
    region_id integer NOT NULL,
    whathood_user_id integer NOT NULL,
    date_time_added character varying(255) NOT NULL,
    polygon geometry(Polygon) NOT NULL,
    is_deleted boolean
);


--
-- Name: COLUMN user_polygon.polygon; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN user_polygon.polygon IS '(DC2Type:polygon)';


--
-- Name: user_polygon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_polygon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    username character varying(255) DEFAULT NULL::character varying,
    email character varying(255) NOT NULL,
    displayname character varying(50) DEFAULT NULL::character varying,
    password character varying(128) NOT NULL,
    state integer NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_roles (
    user_id integer NOT NULL,
    role_id integer NOT NULL
);


--
-- Name: whathood_user; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE whathood_user (
    id integer NOT NULL,
    ip_address character varying(255) NOT NULL
);


--
-- Name: whathood_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE whathood_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- SET search_path = whathood, pg_catalog;

--
-- Name: user_polygon_test_point; Type: VIEW; Schema: whathood; Owner: -
--

CREATE VIEW user_polygon_test_point AS
 SELECT up.id AS user_polygon_id,
    up.polygon,
    n.name AS neighborhood_name,
    n.id AS neighborhood_id
   FROM (user_polygon up
   JOIN neighborhood n ON ((n.id = up.neighborhood_id)));

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY queue_default ALTER COLUMN id SET DEFAULT nextval('queue_default_id_seq'::regclass);


--
-- Name: heatmap_point_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY heatmap_point
    ADD CONSTRAINT heatmap_point_pkey PRIMARY KEY (id);


--
-- Name: neighborhood_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY neighborhood
    ADD CONSTRAINT neighborhood_pkey PRIMARY KEY (id);


--
-- Name: neighborhood_polygon_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY neighborhood_polygon
    ADD CONSTRAINT neighborhood_polygon_pkey PRIMARY KEY (id);


--
-- Name: queue_default_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY queue_default
    ADD CONSTRAINT queue_default_pkey PRIMARY KEY (id);


--
-- Name: region_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY region
    ADD CONSTRAINT region_pkey PRIMARY KEY (id);


--
-- Name: role_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: up_np_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY up_np
    ADD CONSTRAINT up_np_pkey PRIMARY KEY (up_id, np_id);


--
-- Name: user_polygon_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_polygon
    ADD CONSTRAINT user_polygon_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT users_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: whathood_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY whathood_user
    ADD CONSTRAINT whathood_user_pkey PRIMARY KEY (id);


--
-- Name: idx_50b466a6121f828f; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_50b466a6121f828f ON up_np USING btree (np_id);


--
-- Name: idx_50b466a652f241c; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_50b466a652f241c ON up_np USING btree (up_id);


--
-- Name: idx_51498a8ea76ed395; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_51498a8ea76ed395 ON users_roles USING btree (user_id);


--
-- Name: idx_51498a8ed60322ac; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_51498a8ed60322ac ON users_roles USING btree (role_id);


--
-- Name: idx_54d79055803bb24b; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_54d79055803bb24b ON heatmap_point USING btree (neighborhood_id);


--
-- Name: idx_57698a6a727aca70; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_57698a6a727aca70 ON role USING btree (parent_id);


--
-- Name: idx_9a443078803bb24b; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_9a443078803bb24b ON neighborhood_polygon USING btree (neighborhood_id);


--
-- Name: idx_9fa93f185219ebcc; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_9fa93f185219ebcc ON user_polygon USING btree (whathood_user_id);


--
-- Name: idx_9fa93f18803bb24b; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_9fa93f18803bb24b ON user_polygon USING btree (neighborhood_id);


--
-- Name: idx_9fa93f1898260155; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_9fa93f1898260155 ON user_polygon USING btree (region_id);


--
-- Name: idx_fef1e9ee98260155; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_fef1e9ee98260155 ON neighborhood USING btree (region_id);


--
-- Name: name_region_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX name_region_idx ON neighborhood USING btree (name, region_id);


--
-- Name: queue_default_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX queue_default_idx ON queue_default USING btree (id, status);


--
-- Name: region_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX region_name_idx ON region USING btree (name);


--
-- Name: uniq_1483a5e9e7927c74; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX uniq_1483a5e9e7927c74 ON users USING btree (email);


--
-- Name: uniq_1483a5e9f85e0677; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX uniq_1483a5e9f85e0677 ON users USING btree (username);


--
-- Name: uniq_57698a6ab8c2fd88; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX uniq_57698a6ab8c2fd88 ON role USING btree (roleid);


--
-- Name: uniq_9e2afb1622ffd58c; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX uniq_9e2afb1622ffd58c ON whathood_user USING btree (ip_address);


--
-- Name: fk_50b466a6121f828f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY up_np
    ADD CONSTRAINT fk_50b466a6121f828f FOREIGN KEY (np_id) REFERENCES neighborhood_polygon(id);


--
-- Name: fk_50b466a652f241c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY up_np
    ADD CONSTRAINT fk_50b466a652f241c FOREIGN KEY (up_id) REFERENCES user_polygon(id);


--
-- Name: fk_51498a8ea76ed395; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT fk_51498a8ea76ed395 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_51498a8ed60322ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT fk_51498a8ed60322ac FOREIGN KEY (role_id) REFERENCES role(id);


--
-- Name: fk_54d79055803bb24b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY heatmap_point
    ADD CONSTRAINT fk_54d79055803bb24b FOREIGN KEY (neighborhood_id) REFERENCES neighborhood(id);


--
-- Name: fk_57698a6a727aca70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY role
    ADD CONSTRAINT fk_57698a6a727aca70 FOREIGN KEY (parent_id) REFERENCES role(id);


--
-- Name: fk_9a443078803bb24b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY neighborhood_polygon
    ADD CONSTRAINT fk_9a443078803bb24b FOREIGN KEY (neighborhood_id) REFERENCES neighborhood(id);


--
-- Name: fk_9fa93f185219ebcc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_polygon
    ADD CONSTRAINT fk_9fa93f185219ebcc FOREIGN KEY (whathood_user_id) REFERENCES whathood_user(id);


--
-- Name: fk_9fa93f18803bb24b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_polygon
    ADD CONSTRAINT fk_9fa93f18803bb24b FOREIGN KEY (neighborhood_id) REFERENCES neighborhood(id);


--
-- Name: fk_9fa93f1898260155; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_polygon
    ADD CONSTRAINT fk_9fa93f1898260155 FOREIGN KEY (region_id) REFERENCES region(id);


--
-- Name: fk_fef1e9ee98260155; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY neighborhood
    ADD CONSTRAINT fk_fef1e9ee98260155 FOREIGN KEY (region_id) REFERENCES region(id);



--
-- PostgreSQL database dump complete
--
