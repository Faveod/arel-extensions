CREATE OR REPLACE FUNCTION public.find_in_set(n INTEGER, s TEXT)
 RETURNS BOOLEAN
 LANGUAGE sql
AS $function$
    select bool(int4(z.row_number))
    from
    (
        select row_number() over(), y.x
        from (select unnest(('{' || $2 || '}')::int[]) as x) as y
    ) as z
where z.x = $1
$function$
