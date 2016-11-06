IF OBJECT_ID (N'dbo.TRIM', N'FN') IS NOT NULL
    DROP FUNCTION dbo.TRIM;
GO
CREATE FUNCTION dbo.TRIM (@string VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
	RETURN LTRIM(RTRIM(@string));
END;
GO

-----------------------------
-- GO


-- CREATE FUNCTION FIND_IN_SET(@value VARCHAR(MAX), @list VARCHAR(MAX), @delim VARCHAR(MAX))
--	RETURNS VARCHAR(MAX)
--	AS BEGIN
--		RETURN LTRIM(RTRIM(@value));
--	END;

-- GO

IF OBJECT_ID (N'dbo.SplitString', N'FN') IS NOT NULL
    DROP FUNCTION dbo.SplitString;
GO
CREATE FUNCTION dbo.SplitString (@List NVARCHAR(MAX), @Delim VARCHAR(255))
RETURNS TABLE
AS
BEGIN
    RETURN ( SELECT [Value] FROM 
      ( 
        SELECT 
          [Value] = LTRIM(RTRIM(SUBSTRING(@List, [Number],
          CHARINDEX(@Delim, @List + @Delim, [Number]) - [Number])))
        FROM (SELECT Number = ROW_NUMBER() OVER (ORDER BY name)
          FROM sys.all_objects) AS x
          WHERE Number <= LEN(@List)
          AND SUBSTRING(@Delim + @List, [Number], LEN(@Delim)) = @Delim
      ) AS y
    );
END;
