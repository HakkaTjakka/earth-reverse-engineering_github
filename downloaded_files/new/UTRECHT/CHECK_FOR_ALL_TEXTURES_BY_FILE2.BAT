@echo off
REM setlocal ENABLEDELAYEDEXPANSION
setlocal EnableExtensions EnableDelayedExpansion
if exist CHECK_FOR_ALL_TEXTURES.LOG del CHECK_FOR_ALL_TEXTURES.LOG
if exist MISSING_TEXTURES.LOG del MISSING_TEXTURES.LOG
if exist CONVERTED_MTL_FILES.LOG del CONVERTED_MTL_FILES.LOG
if exist CONVERTED_TEXTURE_DIRS.LOG del CONVERTED_TEXTURE_DIRS.LOG
if exist OBJ_FILES.LOG del OBJ_FILES.LOG
if exist NO_OBJ_OR_NBT_FILES.LOG del NO_OBJ_OR_NBT_FILES.LOG
if exist DIR_DOES_NOT_EXIST.LOG del DIR_DOES_NOT_EXIST.LOG
set /a cnt=0

for /f "tokens=*" %%I in (check2.bat) do (
	set /a cnt = !cnt! + 1
	if not exist %%I\checked_ok.txt (
		echo Subdirectory: %%I on %cd% [!cnt!]
		set "l=%%~nI"
		set "result=!l:~0,17!"
		set /a is_corrupt=0
		if exist %%I\!result!.mtl (
			set /a num_in_mtl=0
			set /a num_in_dir=0
			set /a num_missing=0
			set /a num_different_extension=0
			set /a no_jpg=0
			set /a need_conversion=0

			for %%X in (%%I\!result!.mtl) do (
				if not %%~zX == 0 (
					rem dir /b /s %%X
					for /f "tokens=*" %%R in (%%X) do (
						for /f "tokens=1,2" %%a in ("%%R") do (
							REM Note the & behind the %%a otherwise you get a extra space behind !IDENTIFIER! (New MS introduced bug to sabotage EVERYTHING)
							set IDENTIFIER=%%a& set TEXTURE=%%b
							set "COMPARE=map_Kd"
							if !IDENTIFIER!==!COMPARE! (
								set /a num_in_mtl=!num_in_mtl! + 1
								for /f "tokens=1,2 delims==." %%c in ("!TEXTURE!") do (
									set NAME=%%c
									set EXTENSION=%%d
								)
								if not "!EXTENSION!"=="jpg" set /a no_jpg=1
								if exist %%I\!TEXTURE! (
									set /a num_in_dir=!num_in_dir! + 1
									if not exist %%I\!NAME!.jpg (
										set /a need_conversion=1
									)
								) else (
									if not exist %%I\!NAME!.jpg (
										if not exist %%I\!NAME!.bmp (
											if not exist %%I\!NAME!.png (
												set /a num_missing=!num_missing! + 1
											) else (
												set /a num_in_dir=!num_in_dir! + 1
												set /a need_conversion=1
												set /a num_different_extension=!num_different_extension! + 1
											)
										) else (
											set /a num_in_dir=!num_in_dir! + 1
											set /a need_conversion=1
											set /a num_different_extension=!num_different_extension! + 1
										)
									) else (
										set /a num_in_dir=!num_in_dir! + 1
										set /a num_different_extension=!num_different_extension! + 1
									)
								)
							)
						)
					)
				) else (
					echo File %%X is empty
					echo File %%X is empty >> CHECK_FOR_ALL_TEXTURES.LOG
				)
			)
			if not !num_missing! EQU 0 (
				set /a diff=!num_in_mtl! - !num_in_dir!
				echo Subdirectory: %%I has !num_missing![!diff!] missing textures, must be !num_in_mtl!, in dir !num_in_dir!, moving to CORRUPTED_OCTANTS
				echo Subdirectory: %%I has !num_missing![!diff!] missing, must be !num_in_mtl!, in dir !num_in_dir! >> CHECK_FOR_ALL_TEXTURES.LOG
				echo %%I Missing !num_missing! textures >> MISSING_TEXTURES.LOG
				set /a is_corrupt = 1
			) else (
				if exist %%I\!result!.obj (
					if exist %%I\!result!.nbt (
						echo Subdirectory: %%I has .obj and .nbt file, moving %%I\!result!.obj to directory obj
						echo %%I has .obj and .nbt file, moving %%I\!result!.obj to directory obj >> CHECK_FOR_ALL_TEXTURES.LOG
						if not exist obj mkdir obj
						move %%I\!result!.obj obj >NUL
					) else (
						echo Subdirectory: %%I has .obj file
						echo %%I has .obj file >> CHECK_FOR_ALL_TEXTURES.LOG
						echo %%I has .obj file >> OBJ_FILES.LOG
					)
				) else (
					if not exist %%I\!result!.nbt (
						echo Subdirectory: %%I has no .obj file and no .nbt file, moving to CORRUPTED_OCTANTS
						echo %%I has no .obj file and no .nbt file >> CHECK_FOR_ALL_TEXTURES.LOG
						echo %%I has no .obj file and no .nbt file >> NO_OBJ_OR_NBT_FILES.LOG
						set /a is_corrupt = 1
					)
				)
				if not !need_conversion! EQU 0 (
					echo Subdirectory: %%I containes non .jpg files, converting textures to .jpg
					echo Non .jpg files found in %%I, converting textures to .jpg >> CHECK_FOR_ALL_TEXTURES.LOG
					call :CONVERT_TEXTURES %%I
					echo %%I Converted >> CONVERTED_TEXTURE_DIRS.LOG
				)
				if not !no_jpg! EQU 0 (
					echo File:         %%I\!result!.mtl containes .jpg names, converting .mtl file
					echo Non .jpg names found in %%I\!result!.mtl, converting .mtl file >> CHECK_FOR_ALL_TEXTURES.LOG
					call :CONVERT_MTL %%I
					echo %%I\!result!.mtl Converted >> CONVERTED_MTL_FILES.LOG
				)
				if not !num_in_dir! EQU !num_in_mtl! (
					set /a diff=!num_in_dir! - !num_in_mtl! 
					echo Number in %%I=!num_in_mtl! number of textures in dir %%I=!num_in_dir!, difference=!diff!, moving to CORRUPTED_OCTANTS
					echo Number in %%I=!num_in_mtl! number of textures in dir %%I=!num_in_dir!, difference=!diff! >> CHECK_FOR_ALL_TEXTURES.LOG
					set /a is_corrupt = 1
				)
			)
		) else (
			echo Subdirectory: %%I has no file %%I\!result!.mtl, moving to CORRUPTED_OCTANTS
			echo Subdirectory: %%I has no file %%I\!result!.mtl >> CHECK_FOR_ALL_TEXTURES.LOG
			set /a is_corrupt = 1
		)
		if not !is_corrupt! EQU 0 (
			if not exist CORRUPTED_OCTANTS mkdir CORRUPTED_OCTANTS
			if exist %%I (
				REM move %%I CORRUPTED_OCTANTS >NUL
				move %%I CORRUPTED_OCTANTS >NUL
				echo %%I TO CORRUPTED_OCTANTS >> TO_CORUPTED_OCTANTS.LOG
				echo MOVING %%I TO CORRUPTED_OCTANTS
			) else (
				echo Subdirectory: %%I DOES NOT EXIST!!!!!!!!
			)
			set "l=%%I"
			set "result=!l:~15,19!"
			echo node DUMP_OBJ_CITY.js !result! 21 --parallel-search --UTRECHT >> GET_THIS_OCTANTS.BAT
		) else (
			echo ok >> %%I\checked_ok.txt
		)
	) else (
		echo Subdirectory: %%I on %cd% already checked. [!cnt!]
	)
)

pause
exit /b

:CONVERT_TEXTURES
dir %1\*.bmp /s/b > png_and_bmp.txt 2>NUL
dir %1\*.png /s/b >> png_and_bmp.txt 2>NUL
for %%a in (png_and_bmp.txt) do (
	if not %%~za == 0 (
		"C:\Program Files\IrfanView\i_view64.exe" /filelist=png_and_bmp.txt /convert=%1\$N.jpg
		del %1\*.png /s >NUL 2>NUL 
		del %1\*.bmp /s >NUL 2>NUL
		rem echo Converted textures to .jpg
		rem bash -c "./convert_to_jpg_mtl_files.sh %1" 2>NUL
	)
)
if exist png_and_bmp.txt del png_and_bmp.txt /Q
exit /b

:CONVERT_MTL
rem bash -c "./convert_to_jpg_mtl_files.sh %1" 2>NUL
bash -c "./convert_to_jpg_mtl_files.sh %1" 2>NUL
exit /b
