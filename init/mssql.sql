IF OBJECT_ID (N'dbo.TRIM', N'FN') IS NOT NULL
    DROP FUNCTION dbo.TRIM;
GO
CREATE FUNCTION dbo.TRIM (@string VARCHAR(MAX))
RETURNS VARCHAR(MAX) AS
BEGIN
	RETURN LTRIM(RTRIM(@string));
END;
GO

IF OBJECT_ID (N'dbo.TrimChar', N'FN') IS NOT NULL
    DROP FUNCTION dbo.TrimChar;
GO
CREATE FUNCTION dbo.TrimChar(@value nvarchar(4000), @c nchar(1))
RETURNS nvarchar(4000) AS
BEGIN
	set @value = REPLACE(@value, ' ', '~')	-- replace all spaces with an unused character
	set @value = REPLACE(@value, @c, ' ')	-- replace the character to trim with a space
	set @value = LTRIM(RTRIM(@value))		-- trim
	set @value = REPLACE(@value, ' ', @c)	-- replace back all spaces with the trimmed character
	set @value = REPLACE(@value, '~', ' ')	-- replace back all never-used characters with a space

	RETURN @value
END;
GO

IF OBJECT_ID (N'dbo.SplitStringWithDelim', N'IF') IS NOT NULL
    DROP FUNCTION dbo.SplitStringWithDelim;
GO
CREATE FUNCTION dbo.SplitStringWithDelim(@List NVARCHAR(4000), @Delimiter NCHAR(1))
RETURNS TABLE AS
RETURN
(
    WITH SplitStringCte(stpos,endpos)
    AS(
        SELECT 0 AS stpos, CHARINDEX(@Delimiter, @List) AS endpos
        UNION ALL
        SELECT endpos + 1, CHARINDEX(@Delimiter, @List, endpos + 1)
            FROM SplitStringCte
            WHERE endpos > 0
    )
    SELECT 'Id' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
        'Data' = SUBSTRING(@List, stpos, COALESCE(NULLIF(endpos, 0), LEN(@List) + 1) - stpos)
    FROM SplitStringCte
)
GO

IF OBJECT_ID (N'dbo.FIND_IN_SET', N'FN') IS NOT NULL
    DROP FUNCTION dbo.FIND_IN_SET;
GO
CREATE FUNCTION dbo.FIND_IN_SET(@Value VARCHAR(MAX), @List VARCHAR(MAX), @Delimiter VARCHAR(MAX))
RETURNS BIGINT
AS
BEGIN
    RETURN COALESCE((SELECT MIN(Id) FROM dbo.SplitStringWithDelim(@List, COALESCE(@Delimiter, ',')) WHERE Data = @Value), 0)
END
GO

IF OBJECT_ID (N'dbo.LEVENSHTEIN_DISTANCE', N'FN') IS NOT NULL
    DROP FUNCTION dbo.LEVENSHTEIN_DISTANCE;
GO
CREATE FUNCTION dbo.LEVENSHTEIN_DISTANCE(@s nvarchar(4000), @t nvarchar(4000))
RETURNS int
AS
BEGIN
  DECLARE @sl int, @tl int, @i int, @j int, @sc nchar, @c int, @c1 int,
    @cv0 nvarchar(4000), @cv1 nvarchar(4000), @cmin int
  SELECT @sl = LEN(@s), @tl = LEN(@t), @cv1 = '', @j = 1, @i = 1, @c = 0
  WHILE @j <= @tl
    SELECT @cv1 = @cv1 + NCHAR(@j), @j = @j + 1
  WHILE @i <= @sl
  BEGIN
    SELECT @sc = SUBSTRING(@s, @i, 1), @c1 = @i, @c = @i, @cv0 = '', @j = 1, @cmin = 4000
    WHILE @j <= @tl
    BEGIN
      SET @c = @c + 1
      SET @c1 = @c1 - CASE WHEN @sc = SUBSTRING(@t, @j, 1) THEN 1 ELSE 0 END
      IF @c > @c1 SET @c = @c1
      SET @c1 = UNICODE(SUBSTRING(@cv1, @j, 1)) + 1
      IF @c > @c1 SET @c = @c1
      IF @c < @cmin SET @cmin = @c
      SELECT @cv0 = @cv0 + NCHAR(@c), @j = @j + 1
    END
    SELECT @cv1 = @cv0, @i = @i + 1
  END
  RETURN @c
END
GO

--IF OBJECT_ID (N'dbo.SplitString', N'FN') IS NOT NULL
--    DROP FUNCTION dbo.SplitString;
--GO
--CREATE FUNCTION dbo.SplitString (@List NVARCHAR(MAX), @Delim VARCHAR(255))
--RETURNS TABLE
--AS
--BEGIN
--    RETURN ( SELECT [Value] FROM
--      (
--        SELECT
--          [Value] = LTRIM(RTRIM(SUBSTRING(@List, [Number],
--          CHARINDEX(@Delim, @List + @Delim, [Number]) - [Number])))
--        FROM (SELECT Number = ROW_NUMBER() OVER (ORDER BY name)
--          FROM sys.all_objects) AS x
--          WHERE Number <= LEN(@List)
--          AND SUBSTRING(@Delim + @List, [Number], LEN(@Delim)) = @Delim
--      ) AS y
--    );
--END;
