@echo off
echo ========================================
echo    Uploading ahmad-insta to GitHub
echo ========================================
echo.

echo Step 1: Adding project title to README.md...
echo # ahmad-insta >> README.md
echo ✓ README.md updated

echo.
echo Step 2: Initializing Git repository...
git init
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Error: Git is not installed or not in PATH
    echo Please install Git from: https://git-scm.com/download/win
    pause
    exit /b 1
)
echo ✓ Git repository initialized

echo.
echo Step 3: Adding README.md to staging area...
git add README.md
echo ✓ README.md added to staging

echo.
echo Step 4: Creating first commit...
git commit -m "first commit"
echo ✓ First commit created

echo.
echo Step 5: Renaming branch to main...
git branch -M main
echo ✓ Branch renamed to main

echo.
echo Step 6: Adding remote origin...
git remote add origin https://github.com/Ahmad7-7/ahmad-insta.git
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  Remote origin might already exist, updating...
    git remote set-url origin https://github.com/Ahmad7-7/ahmad-insta.git
)
echo ✓ Remote origin configured

echo.
echo Step 7: Pushing to GitHub...
echo ⚠️  Make sure you have created the repository on GitHub first!
echo Repository URL: https://github.com/Ahmad7-7/ahmad-insta
echo.
git push -u origin main

if %ERRORLEVEL% EQ 0 (
    echo.
    echo ========================================
    echo ✅ SUCCESS! Project uploaded to GitHub
    echo ========================================
    echo Your project is now available at:
    echo https://github.com/Ahmad7-7/ahmad-insta
) else (
    echo.
    echo ========================================
    echo ❌ Push failed - Common solutions:
    echo ========================================
    echo 1. Make sure the repository exists on GitHub
    echo 2. Check your GitHub authentication
    echo 3. Use Personal Access Token instead of password
    echo 4. Or try using SSH: git@github.com:Ahmad7-7/ahmad-insta.git
)

echo.
pause