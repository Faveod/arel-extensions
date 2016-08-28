CREATE OR REPLACE FUNCTION find_in_set(
  i_value  IN  VARCHAR2,
  i_list   IN  VARCHAR2,
  i_delim  IN  VARCHAR2 DEFAULT ','
) RETURN INT DETERMINISTIC
AS
  p_result       INT       := 0;
  p_start        NUMBER(5) := 1;
  p_end          NUMBER(5);
  c_len CONSTANT NUMBER(5) := LENGTH( i_list );
  c_ld  CONSTANT NUMBER(5) := LENGTH( i_delim );
BEGIN
  IF c_len > 0 THEN
    p_end := INSTR( i_list, i_delim, p_start );
    WHILE p_end > 0 LOOP
      p_result := p_result + 1;
      IF ( SUBSTR( i_list, p_start, p_end - p_start ) = i_value )
      THEN
        RETURN p_result;
      END IF;
      p_start := p_end + c_ld;
      p_end := INSTR( i_list, i_delim, p_start );
    END LOOP;
    IF p_start <= c_len + 1
       AND SUBSTR( i_list, p_start, c_len - p_start + 1 ) = i_value
    THEN
      RETURN p_result + 1;
    END IF;
  END IF;
  RETURN 0;
END;
