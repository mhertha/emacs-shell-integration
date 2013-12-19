@echo off
REM 2013.01.07: Maik Hertha (mh@mhitc.de)
REM
REM Skript zum Starten eines Emacs-Clients. Dieses erfordert
REM auf dem Rechner einen laufenden emacs-server Process.
REM Wird dieser nicht gefunden, wird automatisch ein alternativer
REM Editor gestartet. Hier emacs als neuer Prozess ohne Server
REM Anbindung.
REM
"%~dp0emacsclientw.exe" -n -a "%~dp0runemacs.exe" "%*"