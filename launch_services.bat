@echo off
:: This script is invoked by run.bat and executes background engines with UTF-8 compliance.

set PHOENIX_SQL_DATABASE_URL=sqlite:///D:\llm_project\phoenix_data.db

:: Launch Phoenix Server and pipe output to a dedicated log file
start /b cmd /c "phoenix serve >> D:\llm_project\logs\phoenix_current.log 2>&1"
:: Pause briefly to allow internal database binds
timeout /t 2 /nobreak > nul

:: Force Python to handle Unicode symbols cleanly, preventing the banner crash
cd /d D:\llm_project
start /b cmd /c "set PYTHONIOENCODING=utf-8 && litellm --config config.yaml --host 127.0.0.1 >> D:\llm_project\logs\litellm_current.log 2>&1"