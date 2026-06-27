@echo off
title LLM Infrastructure Stack Orchestrator

:: Force the current terminal session to execute from your project root folder explicitly
cd /d "D:\llm_project"

:: Force the command processor to read and execute string mappings using UTF-8 encoding compliance
chcp 65001 > nul

:: Ensure log directory exists
if not exist "D:\llm_project\logs" mkdir "D:\llm_project\logs"

echo =================================================== > D:\llm_project\logs\orchestrator.log
echo   Starting Local LLM Proxy and Observability Stack >> D:\llm_project\logs\orchestrator.log
echo   Timestamp: %date% %time%                         >> D:\llm_project\logs\orchestrator.log
echo =================================================== >> D:\llm_project\logs\orchestrator.log

:: Use an absolute path reference to call service.bat cleanly
call "D:\llm_project\launch_services.bat" >> D:\llm_project\logs\orchestrator.log 2>&1

echo Infrastructure engines successfully initialized in background!
echo Check D:\llm_project\logs\orchestrator.log for initialization logs.
echo.
echo Proxy Dashboard:   http://127.0.0.1:4000/ui
echo Phoenix Traces:    http://127.0.0.1:6006
echo ===================================================
timeout /t 5