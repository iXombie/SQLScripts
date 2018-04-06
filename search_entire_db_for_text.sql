
declare @SearchStr nvarchar(100) = '%STRING%'
declare @COLUMNNAMELIKE nvarchar(100) = null
declare @TABLENAMELIKE nvarchar(100) = null;

if OBJECT_ID('tempdb..#Results') is not null 
	drop table #Results
create table #Results (ColumnName nvarchar(370), ColumnValue nvarchar(3630))

set nocount on

declare @TableName nvarchar(256), @ColumnName nvarchar(128), @SearchStr2 nvarchar(110)
set  @TableName = ''
set @SearchStr2 = QUOTENAME('' + @SearchStr + '','''')

while @TableName IS NOT NULL
begin
	set @ColumnName = ''
	set @TableName = 
	(
		select MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
		from INFORMATION_SCHEMA.TABLES
		where TABLE_TYPE = 'BASE TABLE'
			and (@TABLENAMELIKE is null or INFORMATION_SCHEMA.TABLES.TABLE_NAME like @TABLENAMELIKE)
			and	QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
			and	OBJECTPROPERTY(
					OBJECT_ID(
						QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
						 ), 'IsMSShipped'
						   ) = 0
	)

	while (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
	begin
		SET @ColumnName =
		(
			select MIN(QUOTENAME(COLUMN_NAME))
			from 	INFORMATION_SCHEMA.COLUMNS
			where 		TABLE_SCHEMA	= PARSENAME(@TableName, 2)
				and	TABLE_NAME	= PARSENAME(@TableName, 1)
				and	DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar') --, 'text')
				and (@COLUMNNAMELIKE is null or COLUMN_NAME LIKE @COLUMNNAMELIKE)
				and	QUOTENAME(COLUMN_NAME) > @ColumnName
		)

		if @ColumnName IS NOT NULL
		begin
			declare @sql nvarchar(max) = 'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) 
				FROM ' + @TableName + ' (NOLOCK) ' +
				' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
			--begin try
				insert into #Results exec (@sql)
			--end try
			--begin catch
			--	declare @ErrorMessage nvarchar(4000);
			--	declare @ErrorSeverity int;
			--	declare @ErrorState int;

			--	select 
			--		@ErrorMessage = ERROR_MESSAGE() + ' || ' + @sql,
			--		@ErrorSeverity = ERROR_SEVERITY(),
			--		@ErrorState = ERROR_STATE();

			--	raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
			--end catch
		end
	end	
end

select ColumnName, ColumnValue, COUNT(ColumnName) as NO_OF_REC 
from #Results 
group by ColumnName, ColumnValue 
order by NO_OF_REC desc

drop table #Results