@echo off
REM	Receive in Parameters 3 values: 1 for Target DB, second for Actionn, third for source
	call c:\EMCLI\emcli logout 1>nul 2>&1
	call c:\EMCLI\emcli login -username=emstgus -password=!DEVCC! 1>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_Login.txt 2>&1
	timeout 5 > nul
	set Error_Count=0
	set Error_Count_Cre=0
	set EXTRA_PARM=
	set TIMER_ENCLI=0
	
	FINDSTR /N /I "Already logged" %STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_login.txt 1>nul
	if !errorlevel! neq 0 (					
		FINDSTR /N /I "successful" %STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_login.txt 1>nul
		if !errorlevel! neq 0 (
			echo.There were problems while login into DEVCC remote execution.>>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt
		)
	)
	
	call %SAT_FOLDER%\SAT_Funcs 13
	For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
		set year=%%c
		set mydate=%%a%%b!year:~2,2!)	
	)
	
	for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
		set hour=%%a
		if "!hour:~0,1!" == " " set hour=0!hour:~1,1!
		set TIMEFORM=!hour!%%b
		REM %%c
  	)
	echo.TimeStamp is: !mydate!!TIMEFORM!>>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt 2>>&1
	echo.Parametera are:!array_parameters[%3]!.
	for /F "tokens=1-3 delims= " %%a in ("!array_parameters[%3]!") do (
		set Source_DB=!DB_PKG!
		echo.Source DB is:!Source_DB!.>>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt 2>>&1
		set Targ_DB=%%b
		echo.Target DB is:%%c.>>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt 2>>&1
		set Action=%%a
		echo.Action to be done is:!Action!.>>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt 2>>&1
	)	
	
	
	
				if /I "!Action!" equ "Refresh" (
					
					set EXTRA_PARM=!Source_DB! ON DEMAND
						
					set Job_NM=REF FROM !EXTRA_PARM!
				) else if /I "!Action!" equ "Pdb" (
					set Job_NM=CREATE AND DROP PDB FILES
				) else if /I "!Action!" equ "Backup" (
					set Job_NM=BACKUP DB ON DEMAND
				) else if /I "!Action!" equ "Template" (
					set Job_NM=EMS TEMPLATE ON DEMAND
				) else if /I "!Action!" equ "Unlock" (
					set Job_NM=UNLOCK DB
				) else if /I "!Action!" equ "RefreshTemplate" (
					set EXTRA_PARM=!Source_DB! EMS TEMP ON DEMAND
					REM set EXTRA_PARM=!Source_DB! EMSTMP ON DMD
					set Job_NM=REF FROM !EXTRA_PARM!
					REM set Job_NM=REF FRM !EXTRA_PARM!
					set RefJob_NM=REF FRM !Source_DB! EMSTMP ON DMD
				) else if /I "!Action!" equ "LOCK" (
					set Job_NM=LOCK DB
				) else if /I "!Action!" equ "DISABLE" (
					set Job_NM=DISABLE ARCHIVELOG MODE
				) else if /I "!Action!" equ "ENABLE" (
					set Job_NM=ENABLE ARCHIVELOG MODE
				) else (
					echo.THE SELECTED ACTION IS INVALID, PLEASE CHECK YOUS ORDER FILE.>>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt 
					set DID_FAIL=Y
					exit /b
				)
				
				set SUBMITTED_JOBS=
				set EMCLI_COMMA=	
				
				for %%a in ("%Targ_DB:,=" "%") do (
					set Target_DB=%%~a
					if "!IMPDB:~0,2!" equ "HC" (
						if "!Target_DB!" equ "TRL" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
						if "!Target_DB!" equ "TRP" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
						if "!Target_DB!" equ "TRT" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
					)
					call :SUBMIT_EMCLI_JOB !IMPDB!!Target_DB! %1 %4
					if !errorlevel! neq 0 (
						set DID_FAIL=Y
					) else (
						set SUBMITTED_JOBS=!SUBMITTED_JOBS!!EMCLI_COMMA!!Target_DB!
						set EMCLI_COMMA=,
					)
				)
				
				REM if not "%SUBMITTED_JOBS%" == "" for %%a in ("%SUBMITTED_JOBS:,=" "%") do (
				for %%a in ("%Targ_DB:,=" "%") do (
					set Target_DB=%%~a
					if "!IMPDB:~0,2!" equ "HC" (
						if "!Target_DB!" equ "TRL" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
						if "!Target_DB!" equ "TRP" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
						if "!Target_DB!" equ "TRT" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
					)
					call :MONITORING_EMCLI_JOB !IMPDB!!Target_DB! %1 %4
					if !errorlevel! neq 0 (
						set DID_FAIL=Y
					)
				)
				
				for %%a in ("%Targ_DB:,=" "%") do (
					set Target_DB=%%~a
					if "!IMPDB:~0,2!" equ "HC" (
						if "!Target_DB!" equ "TRL" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
						if "!Target_DB!" equ "TRP" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
						if "!Target_DB!" equ "TRT" (
							set IMPDB=!IMPDB:~0,1!R!IMPDB:~2!
						)
					)
					call :EMCLI_EXIT !IMPDB!!Target_DB! %1 %4
				)
				del %STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt
exit /b 			
				
:SUBMIT_EMCLI_JOB
		set EXIT_STATUS_SUBMIT=0
		set Error_Count_Cre=0
		echo.STARTING JOB [!ACTIVITY!PUM/EMS] %~1 - !Job_NM!.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
		echo.STARTING JOB [!ACTIVITY!PUM/EMS] %~1 - !Job_NM!.
:EMCLI_START
		call c:\EMCLI\emcli logout 2>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 1>nul
		call c:\EMCLI\emcli login -username=emstgus -password=!DEVCC! 2>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 1>nul
		if /I "!Action!" neq "RefreshTemplate" (
			call c:\EMCLI\emcli create_job_from_library -lib_job_name="[!ACTIVITY!PUM/EMS] %~1 - !Job_NM!" -name="[!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM!" -owner=emstgus 1>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
		) else (
			call c:\EMCLI\emcli create_job_from_library -lib_job_name="[!ACTIVITY!PUM/EMS] %~1 - !Job_NM!" -name="[!ACTIVITY!]%~1-!RefJob_NM!-SAT !mydate!!TIMEFORM!" -owner=emstgus 1>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
		)
		if !errorlevel! equ 0 (
			set TIMER_ENCLI=0
			echo.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
			echo.JOB CREATED [!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM!.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
			echo.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
			echo.JOB CREATED [!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM!.
			echo.
		) else (
			if !Error_Count_Cre! equ 3 (
				echo.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt
				echo.[!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM! - Execution FAILED.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1		
				REM Created a dummy output file for log cleanup.
				echo.>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_OUTPUT.txt 2>&1
				set EXIT_STATUS_SUBMIT=1
				REM set DID_FAIL=Y
				REM ECHO.
				REM goto :EMCLI_EXIT
			) else (
				set /A Error_Count_Cre+=1
				echo.[!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM! FAILED TO BE STARTED...ATTEMPT !Error_Count_Cre!.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
				echo.[!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM! FAILED TO BE STARTED...ATTEMPT !Error_Count_Cre!.
				echo.EXTENDING TIME...!TIMER_ENCLI! s...>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
				echo.EXTENDING TIME...!TIMER_ENCLI! s...
				set /A TIMER_ENCLI=TIMER_ENCLI+30
				timeout 30 > nul				
				goto :EMCLI_START
			)
		)
EXIT /B	%EXIT_STATUS_SUBMIT%
:MONITORING_EMCLI_JOB
			set EXIT_STATUS_MONITOR=0
			set Error_Count=0
			echo.MONITORING [!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM!.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
			echo.MONITORING [!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM!.
:EMCLI_LOOP
			call c:\EMCLI\emcli logout 2>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 1>nul
			call c:\EMCLI\emcli login -username=emstgus -password=!DEVCC! 2>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 1>nul
			if /I "!Action!" neq "RefreshTemplate" (
				call c:\EMCLI\emcli get_jobs -name="[!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM!">%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_OUTPUT.txt 2>&1
			) else (
				call c:\EMCLI\emcli get_jobs -name="[!ACTIVITY!]%~1-!RefJob_NM!-SAT !mydate!!TIMEFORM!">%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_OUTPUT.txt 2>&1
			)
			FIND /C /I "SUCCEEDED" %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_OUTPUT.txt 1>nul
			if !errorlevel! equ 0 (
				echo.[!ACTIVITY!]%~1-!Job_NM!-SAT !mydate!!TIMEFORM! WAS EXECUTED SUCCESSFULLY.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
				REM goto :EMCLI_EXIT
			) else (
				FINDSTR /N /I "PROBLEMS Failed Error Suspended:" %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_OUTPUT.txt 1>nul
				if !errorlevel! equ 0 (					
					if !Error_Count! equ 3 (
						echo.[!ACTIVITY!]!Targ_DB!-!Job_NM!-SAT !mydate!!TIMEFORM! FAILED TO BE MONITORED.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
						set EXIT_STATUS_MONITOR=1
						REM set DID_FAIL=Y				
						REM ECHO.
						REM goto :EMCLI_EXIT
					) else (
						set /A Error_Count+=1
						echo.[!ACTIVITY!]!Targ_DB!-!Job_NM!-SAT !mydate!!TIMEFORM! FAILED TO BE MONITORED...ATTEMPT !Error_Count!.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
						echo.[!ACTIVITY!]!Targ_DB!-!Job_NM!-SAT !mydate!!TIMEFORM! FAILED TO BE MONITORED...ATTEMPT !Error_Count!.
						set /A TIMER_ENCLI_SW=TIMER_ENCLI/60
						echo.EXTENDING TIME...!TIMER_ENCLI_SW! mins...>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1						
						echo.EXTENDING TIME...!TIMER_ENCLI_SW! mins...
						set /A TIMER_ENCLI=TIMER_ENCLI+30
						timeout 30 > nul
						goto :EMCLI_LOOP
					)					
				) else (
					FIND /C /I "Running" %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_OUTPUT.txt 1>nul
					if !errorlevel! equ 0 (
						set /A TIMER_ENCLI_SW=TIMER_ENCLI/60
						echo.EXTENDING TIME...!TIMER_ENCLI_SW! Mins...>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
						echo.EXTENDING TIME...!TIMER_ENCLI_SW! Mins...
						set /A TIMER_ENCLI=TIMER_ENCLI+30
						set Error_Count=0
						timeout 20 > nul
						goto :EMCLI_LOOP
					) else (
						set /A Error_Count+=1
						echo.UNEXPECTED error in DEVCC, Please check the logs for more details, rerunning ...ATTEMPT !Error_Count!.>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1
						echo.UNEXPECTED error in DEVCC, Please check the logs for more details, rerunning ...ATTEMPT !Error_Count!
						echo.EXTENDING TIME...!TIMER_ENCLI! s...>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 2>>&1						
						echo.EXTENDING TIME...!TIMER_ENCLI! s...
						set /A TIMER_ENCLI=TIMER_ENCLI+30
						timeout 30 > nul
						goto :EMCLI_LOOP
					)
				)
			)
		exit /b	%EXIT_STATUS_MONITOR%	
	REM echo.THE SELECTED ACTION IS INVALID, PLEASE CHECK YOUS ORDE FILE.>>%STAGEDIR%\DB_Logs\%1%4%APP%_%BUILDID%_log.txt 
	REM set DID_FAIL=Y
:EMCLI_EXIT
	type %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_log.txt>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt 1>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt 2>>&1
	type %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt 1>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt 2>>&1
	move %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_OUTPUT.txt %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_OUTPUT.txt 1>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt 2>>&1
	type %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_OUTPUT.txt>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt 2>>&1
	del %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_OUTPUT.txt 1>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt
	del %STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_%~1_log.txt 1>>%STAGEDIR%\DB_Logs\%~2%~3%APP%_%BUILDID%_!Action!_%~1_log.txt
	exit /b
