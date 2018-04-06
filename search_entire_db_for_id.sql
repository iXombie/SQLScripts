-- A very bruteforce method to trying to find how data links. This is a variation on another script that I had come across. If I can find the source, I will give the props

declare @SEARCHID int = 2572
declare @SEARCHCOLUMNNAMELIKE nvarchar(100) = '%ID';
declare @TABLENAMELIKE nvarchar(100) = null;

if OBJECT_ID('tempdb..#IDResults') is not null drop table #IDResults
create table #IDResults (TABLENAME nvarchar(370), VALUE nvarchar(3630))

set nocount on

declare @TABLENAME nvarchar(256), @COLUMNNAME nvarchar(128);
set  @TABLENAME = ''

while @TABLENAME IS NOT NULL
begin
	SET @COLUMNNAME = ''
	set @TABLENAME = 
	(
		select MIN(QUOTENAME(INFORMATION_SCHEMA.TABLES.TABLE_SCHEMA) + '.' + QUOTENAME(INFORMATION_SCHEMA.TABLES.TABLE_NAME))
		from  INFORMATION_SCHEMA.TABLES
			inner join INFORMATION_SCHEMA.COLUMNS on INFORMATION_SCHEMA.TABLES.TABLE_NAME = INFORMATION_SCHEMA.COLUMNS.TABLE_NAME
		where TABLE_TYPE = 'BASE TABLE'
			and (@SEARCHCOLUMNNAMELIKE is null or INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME like @SEARCHCOLUMNNAMELIKE)
			and (@TABLENAMELIKE is null or INFORMATION_SCHEMA.TABLES.TABLE_NAME like @TABLENAMELIKE)
			and	QUOTENAME(INFORMATION_SCHEMA.TABLES.TABLE_SCHEMA) + '.' + QUOTENAME(INFORMATION_SCHEMA.TABLES.TABLE_NAME) > coalesce(@TABLENAME,'')
			and	OBJECTPROPERTY(OBJECT_ID(QUOTENAME(INFORMATION_SCHEMA.TABLES.TABLE_SCHEMA) + '.' + QUOTENAME(INFORMATION_SCHEMA.TABLES.TABLE_NAME)), 'IsMSShipped') = 0
	)
	
	WHILE (@TABLENAME IS NOT NULL) AND (@COLUMNNAME IS NOT NULL)
	BEGIN
		SET @COLUMNNAME =
		(
			select MIN(QUOTENAME(COLUMN_NAME))
			from 	INFORMATION_SCHEMA.COLUMNS
			where TABLE_SCHEMA = PARSENAME(@TableName, 2)
				and	TABLE_NAME = PARSENAME(@TableName, 1)
				and	DATA_TYPE in ('int')
				and COLUMN_NAME like @SEARCHCOLUMNNAMELIKE
				and	QUOTENAME(COLUMN_NAME) > @COLUMNNAME
		)
		IF @COLUMNNAME IS NOT NULL
		begin
			print 'select * from '+ @TABLENAME + ' where ' + @COLUMNNAME + ' = ' + convert(nvarchar(255), @SEARCHID)
			insert into #IDResults
			exec
			(
				'select ''' + @TABLENAME + '.' + @COLUMNNAME + ''', LEFT(' + @COLUMNNAME + ', 3630) 
				from ' + @TABLENAME + ' (NOLOCK) ' +
				' where ' + @COLUMNNAME + ' = ' + @SEARCHID
			)
		end
	end
end

select TABLENAME, VALUE, COUNT(*) as NO_OF_REC from #IDResults group by TABLENAME, VALUE order by NO_OF_REC desc
drop table #IDResults