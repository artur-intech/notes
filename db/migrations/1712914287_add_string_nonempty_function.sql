CREATE FUNCTION string_nonempty(string text) RETURNS bool
    LANGUAGE SQL
    IMMUTABLE
    RETURNS NULL ON NULL INPUT
    RETURN ((string)::text = ''::text) IS NOT TRUE;
