@echo off

for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":4000" ^| findstr "LISTENING"') do (
    taskkill /PID %%a /F >nul 2>&1
)

exit