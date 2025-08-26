@echo off
echo UPLOADING TO GITHUB...
echo.

cd /d "c:\Users\ahmed\Downloads\My Projects\ahmad-insta\ahmad-insta"

echo "# ahmad-insta" >> README.md
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/Ahmad7-7/ahmad-insta.git 2>nul
git remote set-url origin https://github.com/Ahmad7-7/ahmad-insta.git
git push -u origin main

echo.
echo FERTIG! Check: https://github.com/Ahmad7-7/ahmad-insta
pause