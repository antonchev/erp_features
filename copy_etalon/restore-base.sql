DECLARE @SQLString NVARCHAR(4000)
DECLARE @backupfile NVARCHAR(500)
DECLARE @physicalName NVARCHAR(500), @logicalName NVARCHAR(500)
DECLARE @error as int
DECLARE @subject as NVARCHAR(100)
DECLARE @finalmassage as NVARCHAR(1000)
DECLARE @DBName_From as nvarchar(40)
set @DBName_From = '$(dbname_from)'
DECLARE @DBName_To as nvarchar(40)
set @DBName_To = '$(dbname_to)'
DECLARE @DBdate datetime2
set @DBdate = '$(dbdate)'



DECLARE @DBdate_to datetime2
DECLARE @DBdate_from datetime2


SET @DBdate_from = DATEADD(SECOND,86399,@DBdate)
set @DBdate_from = CONVERT(VARCHAR, @DBdate_from, 0)
SET @DBdate_to = DATEADD(SECOND,1,@DBdate)
set @DBdate_to = CONVERT(VARCHAR, @DBdate_to, 0)



SELECT
	backupset.backup_start_date,
	backupset.backup_set_uuid,
	backupset.differential_base_guid,
	backupset.[type] as btype,
	backupmediafamily.physical_device_name
INTO #BackupFiles	
FROM msdb.dbo.backupset AS backupset
    INNER JOIN msdb.dbo.backupmediafamily AS backupmediafamily 
	ON backupset.media_set_id = backupmediafamily.media_set_id
WHERE backupset.database_name = @DBName_From
	and backupset.backup_start_date < @DBdate_from
	and backupset.backup_start_date > @DBdate_to
	and backupset.is_copy_only = 0 -- флаг "Только резервное копирование"
	and backupset.is_snapshot = 0 -- флаг "Не snapshot"
	and (backupset.description is null or backupset.description not like 'Image-level backup') -- Защита от Veeam Backup & Replication
	and device_type <> 7
ORDER BY 
	backupset.backup_start_date DESC


	SELECT TOP 1
	BackupFiles.backup_start_date,
	BackupFiles.physical_device_name,
	BackupFiles.backup_set_uuid	
INTO #FullBackup	 
FROM #BackupFiles AS BackupFiles
WHERE btype = 'D'
ORDER BY backup_start_date DESC

	

	DECLARE bkf CURSOR LOCAL FAST_FORWARD FOR 
(
	SELECT physical_device_name
	FROM #FullBackup
);
	select * from #FullBackup
	OPEN bkf;

-- Прочитаем первый элемент цикла, им может быть только полная резервная копия
FETCH bkf INTO @backupfile;
IF @@FETCH_STATUS<>0
	-- Если получить элемент не удалось, то полная резерная копия не найдена
	BEGIN
		SET @subject = 'ОШИБКА ВОССТАНОВЛЕНИЯ базы данных ' + @DBName_To
		SET @finalmassage = 'Не найдена полная резервная копия для базы данных ' + @DBName_From
	END
ELSE
	

SET @SQLString = 
	N'RESTORE DATABASE [' + @DBName_To + ']
	FROM DISK = N''' + @backupfile + ''' 
	WITH  
	FILE = 1,'

	-- Переименуем файлы базы данных на исходные
	-- Новый цикл по всем файлам базы данных
	DECLARE fnc CURSOR LOCAL FAST_FORWARD FOR 
	(
		SELECT
			t_From.name,
			t_To.physical_name
		FROM sys.master_files as t_To 
			join sys.master_files as t_From 
			on t_To.file_id = t_From.file_id
		WHERE t_To.database_id = DB_ID(@DBName_To) 
			and t_From.database_id = DB_ID(@DBName_From)
	)
	OPEN fnc;
	FETCH fnc INTO @logicalName, @physicalName;
	WHILE @@FETCH_STATUS=0
		BEGIN
			SET @SQLString = @SQLString + '
			MOVE N''' + @logicalName + ''' TO N''' + @physicalName + ''','
			FETCH fnc INTO @logicalName, @physicalName;
		END;
	CLOSE fnc;
	DEALLOCATE fnc;

	SET @SQLString = @SQLString + '
	REPLACE,
	STATS = 5'

	-- Выводим и выполняем полученную инструкцию
	PRINT @SQLString
	--EXEC sp_executesql @SQLString
	PRINT @subject
	PRINT @finalmassage

	




drop table #BackupFiles
drop table #FullBackup
