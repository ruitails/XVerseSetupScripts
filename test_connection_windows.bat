@echo off
REM Windows batch script to test SSH connection
REM Note: This requires WSL or Git Bash to run bash commands

echo Testing SSH connection...
echo.
echo Note: This script requires sshpass which is not available on Windows.
echo You need to run this on Ubuntu or use WSL (Windows Subsystem for Linux).
echo.
echo To test the connection, you can:
echo 1. Use WSL: wsl bash test_single_connection.sh
echo 2. Use Git Bash: bash test_single_connection.sh
echo 3. Run on Ubuntu machine directly
echo.
echo Manual test command:
echo sshpass -p 'seame' ssh -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no seame@100.77.8.52 "echo Connection successful"
echo.
pause
