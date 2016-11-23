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

IF OBJECT_ID (N'dbo.SplitString', N'FN') IS NOT NULL
    DROP FUNCTION dbo.SplitString;
GO
CREATE FUNCTION dbo.SplitString(@List NVARCHAR(4000), @Delimiter NCHAR(1))
RETURNS TABLE AS
RETURN
(
    WITH SplitString(stpos,endpos)
    AS(
        SELECT 0 AS stpos, CHARINDEX(@Delimiter, @List) AS endpos
        UNION ALL
        SELECT endpos + 1, CHARINDEX(@Delimiter, @List, endpos + 1)
            FROM SplitString
            WHERE endpos > 0
    )
    SELECT 'Id' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
        'Data' = SUBSTRING(@List, stpos, COALESCE(NULLIF(endpos, 0), LEN(@List) + 1) - stpos)
    FROM SplitString
)
GO

IF OBJECT_ID (N'dbo.FIND_IN_SET', N'FN') IS NOT NULL
    DROP FUNCTION dbo.FIND_IN_SET;
GO
CREATE FUNCTION dbo.FIND_IN_SET(@Value VARCHAR(MAX), @List VARCHAR(MAX), @Delimiter VARCHAR(MAX))
RETURNS BIGINT
AS
BEGIN
    RETURN COALESCE((SELECT MIN(Id) FROM dbo.SplitString(@List, COALESCE(@Delimiter, ',')) WHERE Data = @Value), 0)
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
