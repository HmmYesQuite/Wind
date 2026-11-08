@echo off
rem Exports each tag of the player .aseprite file to its own horizontal strip: player_<tag>.png
rem Save in Aseprite first, then double-click this. Add new animation tag names to TAGS.
set ASEPRITE=C:\dev\aseprite\build\bin\aseprite.exe
set SOURCE=PlayerSprite.aseprite
set TAGS=idle walk Sit

cd /d "%~dp0"
for %%t in (%TAGS%) do (
	"%ASEPRITE%" -b --tag %%t "%SOURCE%" --sheet-type horizontal --sheet "player_%%t.png" >nul
	echo Exported player_%%t.png
)
