CREATE OR REPLACE FUNCTION public.find_in_set(n INTEGER, s TEXT)
 RETURNS INT4
 LANGUAGE sql
AS $function$
    SELECT * FROM (
      select int4(z.row_number) from (
        select row_number() over(), y.x
        from (select unnest(('{' || $2 || '}')::int[]) as x) as y
      ) as z
      where z.x = $1
    UNION ALL
      SELECT 0) z
    LIMIT 1
$function$
;

CREATE OR REPLACE FUNCTION public.levenshtein_distance(s text, t text)
RETURNS integer AS $$
DECLARE i integer;
DECLARE j integer;
DECLARE m integer;
DECLARE n integer;
DECLARE d integer[];
DECLARE c integer;

BEGIN
	m := char_length(s);
	n := char_length(t);

	i := 0;
	j := 0;

	FOR i IN 0..m LOOP
		d[i*(n+1)] = i;
	END LOOP;

	FOR j IN 0..n LOOP
		d[j] = j;
	END LOOP;

	FOR i IN 1..m LOOP
		FOR j IN 1..n LOOP
			IF SUBSTRING(s,i,1) = SUBSTRING(t, j,1) THEN
				c := 0;
			ELSE
				c := 1;
			END IF;
			d[i*(n+1)+j] := LEAST(d[(i-1)*(n+1)+j]+1, d[i*(n+1)+j-1]+1, d[(i-1)*(n+1)+j-1]+c);
		END LOOP;
	END LOOP;

	return d[m*(n+1)+n];
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.DateDiff(units VARCHAR(30), start_t TIMESTAMP, end_t TIMESTAMP)
     RETURNS INT AS $$
   DECLARE
     diff_interval INTERVAL;
     diff INT = 0;
     years_diff INT = 0;
   BEGIN
     IF units IN ('yy', 'yyyy', 'year', 'mm', 'm', 'month') THEN
       years_diff = DATE_PART('year', end_t) - DATE_PART('year', start_t);

       IF units IN ('yy', 'yyyy', 'year') THEN
         -- SQL Server does not count full years passed (only difference between year parts)
         RETURN years_diff;
       ELSE
         -- If end month is less than start month it will subtracted
         RETURN years_diff * 12 + (DATE_PART('month', end_t) - DATE_PART('month', start_t));
       END IF;
     END IF;

     -- Minus operator returns interval 'DDD days HH:MI:SS'
     diff_interval = end_t - start_t;

     diff = diff + DATE_PART('day', diff_interval);

     IF units IN ('wk', 'ww', 'week') THEN
       diff = diff/7;
       RETURN diff;
     END IF;

     IF units IN ('dd', 'd', 'day') THEN
       RETURN diff;
     END IF;

     diff = diff * 24 + DATE_PART('hour', diff_interval);

     IF units IN ('hh', 'hour') THEN
        RETURN diff;
     END IF;

     diff = diff * 60 + DATE_PART('minute', diff_interval);

     IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
     END IF;

     diff = diff * 60 + DATE_PART('second', diff_interval);

     RETURN diff;
   END;
$$ LANGUAGE plpgsql;
