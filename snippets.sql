--------------------------------------------------------------------------------------
-- A simple collection queries for navigating, disovering, and auto generating queries
--------------------------------------------------------------------------------------

----Look up columns by name
	select * 
	from information_schema.columns 
	where column_name like '%enroll%' --and table_name like 'EA7%'
	order by table_name
	
---- Parameter Lookup for Stored Procedures	
	select 
		PARAMETER_NAME + ' = ' + PARAMETER_NAME + ','
	from information_schema.PARAMETERS 
	where SPECIFIC_NAME = ' USP_DATAFORMTEMPLATE_ADD_ADDRESS_2'
		
---- Get Column Data from a single table
	select * 
	from information_schema.columns 
	where table_name = 'ADDRESS' 
		--and IS_NULLABLE = 'NO'
	order by ORDINAL_POSITION
	
----look for tables containing...
	select * 
	from INFORMATION_SCHEMA.TABLES 
	where TABLE_NAME like '%ATTRIBUTE%' 
	order by table_name
	
---- Get Table Column Information
	select	
		*
	from information_schema.columns 
	where  table_name = 'USERS'
	
---- Column select builder
	select 
		'@'+ COLUMN_NAME + ' = [' + COLUMN_NAME + '],' as [SELECT],
		'[' + COLUMN_NAME + '] = @'+ COLUMN_NAME + ',' as [UPDATE],
		'[' + COLUMN_NAME + '],' as [COLUMNS],
		'@'+ COLUMN_NAME + ' ' + (
			case
				when DOMAIN_NAME is null then
					DATA_TYPE + (
						case
							when CHARACTER_MAXIMUM_LENGTH is not null then
								'('+ CAST(CHARACTER_MAXIMUM_LENGTH as nvarchar(max)) + ')'
							else ''
						end
						)
				else DOMAIN_SCHEMA + '.' + DOMAIN_NAME
			end
			) + ',' as [DECLAREABLES],
			'@'+ COLUMN_NAME +',' as [VARS],
			'@'+ COLUMN_NAME +' = @'+ COLUMN_NAME + ',' as [SP]
	from information_schema.columns 
	where  table_name = 'address'

----Required Columns query
	select 
		COLUMN_NAME, 
		DATA_TYPE, 
		DOMAIN_NAME, 
		IS_NULLABLE, 
		COLUMN_DEFAULT 
	from information_schema.columns 
	where 
		table_name  = 'DEMOGRAPHIC' 
		and IS_NULLABLE = 'NO' 
		and COLUMN_DEFAULT is null
	order by ORDINAL_POSITION

----View Table FK Constraints
	select
	FK_Table = FK.TABLE_NAME,
	FK_Column = CU.COLUMN_NAME,
	PK_Table = PK.TABLE_NAME,
	PK_Column = PT.COLUMN_NAME,
	Constraint_Name = C.CONSTRAINT_NAME
	from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C
	inner join INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK on C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
	inner join INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK on C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
	inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU on C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
	inner join (
	select i1.TABLE_NAME, i2.COLUMN_NAME
	from INFORMATION_SCHEMA.TABLE_CONSTRAINTS i1
	inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE i2 on i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
	where i1.CONSTRAINT_TYPE = 'PRIMARY KEY'
	) PT on PT.TABLE_NAME = PK.TABLE_NAME
	where PK.TABLE_NAME='RECORDS'
	and C.CONSTRAINT_NAME = 'FK_RECORDS_3'