@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================================
echo  Push devops-showcase to GitHub
echo ============================================================
echo.
echo  Step 1: Open this page in your browser and generate a token:
echo  https://github.com/settings/tokens/new
echo  - Note: devops-showcase
echo  - Expiration: 90 days
echo  - Scope: check ONLY "repo"
echo  - Click "Generate token" and copy the ghp_... string
echo.

set /p GH_TOKEN="  Paste your token here: "

if "%GH_TOKEN%"=="" (
  echo  ERROR: token is empty. Run this file again.
  pause
  exit /b 1
)

echo.
echo  Step 2: Configuring remote and pushing...
git remote remove origin 2>nul
git remote add origin "https://%GH_TOKEN%@github.com/ZChos1n/devops-showcase.git"

echo  Step 3: Committing pending files...
git add -A
git diff --cached --quiet || git -c user.name=showcase -c user.email=showcase@example.com commit -q -m "docs: add push guide"

echo  Step 4: Switching branch to main and pushing...
git branch -M main
git push -u origin main
set PUSH_RESULT=%ERRORLEVEL%

echo  Step 5: Cleaning token from git config...
git remote set-url origin "https://github.com/ZChos1n/devops-showcase.git"

echo.
if "%PUSH_RESULT%"=="0" (
  echo  SUCCESS: https://github.com/ZChos1n/devops-showcase
) else (
  echo  FAILED: check the error message above.
  echo  Common causes: wrong token, "repo" scope not checked, or repo name mismatch.
)
echo.
pause
