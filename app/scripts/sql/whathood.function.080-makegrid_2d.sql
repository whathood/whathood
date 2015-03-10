--
--  makegrid_2d
--
-- returns a fishnet grid of points inside the public geometry

--
-- example SELECT whathood.makegrid_2d( ST_GeomFromText('POLYGON((-75.015599208924 40.094871100209,-75.017684142696 40.092756115184,-75.021120774685 40.089131396676,-75.021893591517 40.088315359697,-75.022072443413 40.088174494227,-75.022713576016 40.087500435318,-75.02402677331 40.086165136063,-75.024654567287 40.085430289183,-75.025261521804 40.08482191622,-75.026543071135 40.08361356085,-75.027720495584 40.082364789786,-75.028977266379 40.081003448884,-75.030834609506 40.079068686038,-75.031434741861 40.07850725553,-75.032986261033 40.076799075061,-75.033096394226 40.076777693702,-75.035087383274 40.074618175211,-75.03630956027 40.073333892129,-75.036615939203 40.073089290201,-75.038327705485 40.071270900711,-75.039585848422 40.069851547677,-75.040333981463 40.06875453433,-75.040343531597 40.068740529251,-75.040370673826 40.068631929605,-75.040909530245 40.068944546664,-75.041362247108 40.06929104737,-75.041642678867 40.069705319126,-75.041769292412 40.070280336241,-75.0412705252 40.071104691969,-75.039958256435 40.072228972297,-75.039897982711 40.07267367863,-75.040583588527 40.073646962013,-75.042963463792 40.077054566235,-75.043692575706 40.077482821817,-75.043728316938 40.077849675618,-75.047443934561 40.082913508179,-75.050925581441 40.080271160786,-75.051534338044 40.080623113576,-75.052572322045 40.079583210252,-75.054931074861 40.080980895128,-75.057032245241 40.086780540111,-75.056673911118 40.087065207604,-75.056455111731 40.087428640675,-75.05632844015 40.087819316601,-75.056274229462 40.088325171654,-75.05640814437 40.088780405943,-75.056609728619 40.089108771992,-75.057075065308 40.089751073066,-75.057741769405 40.090020091049,-75.058294568265 40.090183548548,-75.063184689857 40.090541864729,-75.06372228012 40.09059767035,-75.064097378899 40.090677310725,-75.064465350092 40.090876714613,-75.066132744765 40.092469595519,-75.065969101275 40.092674342995,-75.068496909811 40.094637111787,-75.069387192829 40.094482165032,-75.067702999798 40.096224000304,-75.067173999949 40.096771999969,-75.065651000201 40.098353999781,-75.064932999612 40.099092000305,-75.064456999733 40.099584000283,-75.064202999859 40.099845999953,-75.063745000003 40.100320999706,-75.0636030002 40.100466000149,-75.063537000534 40.100533000066,-75.062795999556 40.101300000388,-75.062732000018 40.101366999775,-75.061400999808 40.102741000389,-75.060318000168 40.10385900027,-75.059540000094 40.104655999667,-75.059195999955 40.105010999614,-75.058342000337 40.10589200007,-75.057952999997 40.106163000303,-75.057518000411 40.106376999779,-75.057067000487 40.106631999681,-75.057178000187 40.106693999804,-75.055327999658 40.107990000243,-75.054321000364 40.10869199967,-75.052975000305 40.109635999659,-75.052925000113 40.109668999786,-75.052133999447 40.110220999598,-75.051411587576 40.110725617889,-75.050658000026 40.111251999966,-75.049525999808 40.112041999778,-75.049391999981 40.112135000351,-75.049300000426 40.112198999615,-75.048596836672 40.112690657406,-75.048561801754 40.112672393675,-75.047768961267 40.112250344388,-75.041171098359 40.108401432803,-75.038843425719 40.107113112093,-75.037143359634 40.106964120986,-75.035587124899 40.106747540955,-75.034721987723 40.106272592611,-75.033874828456 40.105723266032,-75.032908603094 40.105153859431,-75.029941398545 40.103288623242,-75.028816794144 40.102560090175,-75.02761689664 40.101841269009,-75.026907778504 40.101588584718,-75.02566804479 40.10111619982,-75.024064882844 40.100738747731,-75.02280198343 40.100411601982,-75.021842936098 40.100099193213,-75.01969773638 40.098299208341,-75.018854965156 40.097646306136,-75.018265893001 40.097074858177,-75.015599208924 40.094871100209))',0.00009);
--
--

DROP FUNCTION whathood.makegrid_2d(
  bound_polygon geometry,
  grid_step numeric
);
CREATE OR REPLACE FUNCTION whathood.makegrid_2d (
  bound_polygon geometry,
  grid_step numeric
)
RETURNS geometry[] AS
$body$
DECLARE
  BoundM public.geometry; --Bound polygon transformed to metric projection (with metric_srid SRID)
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
$body$
LANGUAGE 'plpgsql';
