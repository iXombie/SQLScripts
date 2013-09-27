----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--This script was designed to help simplify the process of exporting a customized 
--tables from clients database for the purpose of being able to test debug against 
--their data. For most customiztion projects tables are usually  named something 
--along the lines of:
--
--cfp_[Client]_[Project]_[Tablename]
--
--Description
--@SOURCEDB is the database the tables are stored in.
--@DESTDB is the temporary database the tables should be exported.
--@TABLESEARCH is the name of search criteria for the tables to export.
--@BACKUPPATH (optional) is the path to which the database should be backed up.
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

declare @SOURCEDB nvarchar(128) = 'Shelby_641';
declare @DESTDB nvarchar(128) = 'test';
declare @TABLESEARCH nvarchar(128) = 'cfp_aub_survey%';
declare @BACKUPPATH nvarchar(128) = 'c:\test\';

-------------------------------------------------
--- NOTHING BELOW THIS LINE SHOULD BE CHANGED ---
-------------------------------------------------
begin try
	set nocount on
	declare @BACKUP bit = 1;

	if (@BACKUPPATH = '' or @BACKUPPATH is null)
	begin
		set @BACKUP = 0;
	end
	else
	begin
		if not @BACKUPPATH LIKE '%\'
		begin
			set @BACKUPPATH = @BACKUPPATH + '\';
		end
	end


	if @BACKUP = 1
	begin
		create table #fileexist_output (
		[FILE_EXISTS]			int	not null,
		[FILE_IS_DIRECTORY]		int	not null,
		[PARENT_DIRECTORY_EXISTS]	int	not null)
		
		insert into #fileexist_output
		exec master.dbo.xp_fileexist @BACKUPPATH
		
		if not exists ( select * from #fileexist_output where FILE_IS_DIRECTORY = 1 )
		begin
			drop table #fileexist_output;
			declare @error nvarchar(max)  = 'Path to backup directory "' + @BACKUPPATH + '" does not exist';
			raiserror(@error, 16, -1);
		end
		else
		begin
			drop table #fileexist_output;
		end
	end

	declare @DBCREATED bit = 0;
	if NOT (EXISTS (select NAME from master.dbo.sysdatabases where NAME = @DESTDB ))
	begin
		exec 
		(
			'create database ' + @DESTDB
		)
		set @DBCREATED = 1
	end


	declare @TABLENAME nvarchar(max), @QUERY nvarchar(max);

	set  @TABLENAME = '';
	set @QUERY = '';

	while @TABLENAME is not null
	begin
		set @QUERY = 'select @TABLENAME = MIN(QUOTENAME(TABLE_SCHEMA) + ''.'' + QUOTENAME(TABLE_NAME))
						from ' + @SOURCEDB + '.INFORMATION_SCHEMA.TABLES
						where TABLE_NAME like ''' + @TABLESEARCH + '''
						and QUOTENAME(TABLE_SCHEMA) + ''.'' + QUOTENAME(TABLE_NAME) > ''' + @TABLENAME + '''';
						
		exec sp_executesql @QUERY, N'@TABLENAME nvarchar(max) out', @TABLENAME out;

		if @TABLENAME is not null
		begin
			exec
			(
				'if OBJECT_ID(''' + @DESTDB + '.'+ @TABLENAME + ''') is null
				 begin
					select * into ' + @DESTDB + '.'+ @TABLENAME + ' from ' + @SOURCEDB +'.'+ @TABLENAME + '
				 end
				 else
				 begin
					print ''Skipping "' + @TABLENAME + '" table already exists''
				 end'
			)
		end
	end

	declare @TABLECOUNT as int;
	declare @TABLECOUNTQUERY as nvarchar(max) = 'select @TABLECOUNT = count(*) from ' + @DESTDB + '.INFORMATION_SCHEMA.TABLES';
	exec sp_executesql @TABLECOUNTQUERY, N'@TABLECOUNT int out', @TABLECOUNT out;

	if @TABLECOUNT > 0
	begin
		if @BACKUP = 1
		begin
			exec
				(
					'backup database ' + @DESTDB +' to disk='''+ @BACKUPPATH + @DESTDB +'.bak'''
				)
			print 'Backup saved to "' + @BACKUPPATH + @DESTDB +'.bak"'
		end
	end
	else
	begin
		print 'No tables were backed up'
	end

	if @DBCREATED = 1 and @BACKUP = 1
	begin
		exec
			(
				'drop database ' + @DESTDB
			)
	end
	print 'Completed'
	
end try
begin catch
	declare @ERRORMESSAGE nvarchar(max), @ERRORSEVERITY int, @ERRORSTATE int;
    select @ERRORMESSAGE = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ERRORSEVERITY = ERROR_SEVERITY(), @ERRORSTATE = ERROR_STATE();
    raiserror (@ERRORMESSAGE, @ERRORSEVERITY, @ERRORSTATE);
end catch