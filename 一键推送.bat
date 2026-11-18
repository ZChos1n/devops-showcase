@echo off
chcp 65001 >nul
cd /d "%~dp0"

REM Set local proxy so git can reach github.com (this machine needs a proxy).
set HTTP_PROXY=http://127.0.0.1:50018
set HTTPS_PROXY=http://127.0.0.1:50018
set http_proxy=http://127.0.0.1:50018
set https_proxy=http://127.0.0.1:50018

echo ============================================================
echo  Push devops-showcase to GitHub
echo ============================================================
echo.
echo  Generate a NEW token at:
echo  https://github.com/settings/tokens/new
echo   - Expiration: 90 days
echo   - Select scopes: check BOTH "repo" and "workflow"
echo     (workflow is needed for .github/workflows files)
echo   - Generate token, then copy the ghp_... string.
echo.
echo  NOTE: The old token was shown in a screenshot. Revoke it at
echo  https://github.com/settings/tokens after this push succeeds.
echo.

set /p GH_TOKEN="  Paste the NEW token here: "

if "%GH_TOKEN%"=="" (
  echo  ERROR: token is empty. Run again.
  pause
  exit /b 1
)

echo.
echo  Configuring remote...
git remote remove origin 2>nul
git remote add origin "https://%GH_TOKEN%@github.com/ZChos1n/devops-showcase.git"

echo  Committing pending files...
git add -A
git diff --cached --quiet || git -c user.name=showcase -c user.email=showcase@example.com commit -q -m "docs: add push guide"

echo  Pushing (branch main)...
git branch -M main
git push -u origin main
set PUSH_RESULT=%ERRORLEVEL%

echo  Cleaning token from git config...
git remote set-url origin "https://github.com/ZChos1n/devops-showcase.git"

echo.
if "%PUSH_RESULT%"=="0" (
  echo  SUCCESS: https://github.com/ZChos1n/devops-showcase
) else (
  echo  FAILED - see error above. Common causes:
  echo   - "workflow" scope not checked
  echo   - proxy changed (edit the 4 proxy lines at top if needed)
  echo   - repo name mismatch
)
echo.
pause
