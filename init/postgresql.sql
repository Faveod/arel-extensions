CREATE OR REPLACE FUNCTION public.pg_find_in_set(n INTEGER, s TEXT)
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