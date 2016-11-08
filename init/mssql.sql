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

-----------------------------
-- GO

IF OBJECT_ID (N'dbo.FIND_IN_SET', N'FN') IS NOT NULL
    DROP FUNCTION dbo.FIND_IN_SET;
GO
-- CREATE FUNCTION dbo.FIND_IN_SET(@value VARCHAR(MAX), @list VARCHAR(MAX), @delim VARCHAR(MAX))
--	RETURNS VARCHAR(MAX)
--	AS BEGIN
--		RETURN LTRIM(RTRIM(@value));
--	END;

-- GO

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
