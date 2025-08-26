# Automatischer GitHub Upload für ahmad-insta
Write-Host "==================================" -ForegroundColor Green
Write-Host "  AHMAD-INSTA GITHUB UPLOAD" -ForegroundColor Green  
Write-Host "==================================" -ForegroundColor Green
Write-Host ""

# Schritt 1: Git Installation prüfen/installieren
Write-Host "Schritt 1: Git Installation prüfen..." -ForegroundColor Yellow

try {
    $gitVersion = git --version 2>$null
    Write-Host "✓ Git ist bereits installiert: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Git nicht gefunden. Installiere Git..." -ForegroundColor Yellow
    
    # Versuche Git über winget zu installieren
    try {
        Write-Host "Installiere Git über Windows Package Manager..." -ForegroundColor Cyan
        winget install --id Git.Git -e --source winget --silent
        Write-Host "✓ Git Installation abgeschlossen!" -ForegroundColor Green
        Write-Host "Bitte das Terminal neustarten und das Script erneut ausführen." -ForegroundColor Red
        Read-Host "Drücke Enter zum Beenden"
        exit
    } catch {
        Write-Host "❌ Automatische Installation fehlgeschlagen." -ForegroundColor Red
        Write-Host "Bitte Git manuell installieren: https://git-scm.com/download/win" -ForegroundColor Red
        Read-Host "Drücke Enter zum Beenden"
        exit
    }
}

# Schritt 2: Verzeichnis wechseln
Write-Host "Schritt 2: Verzeichnis prüfen..." -ForegroundColor Yellow
$projectPath = "C:\Users\ahmed\Downloads\My Projects\ahmad-insta\ahmad-insta"
Set-Location $projectPath
Write-Host "✓ Verzeichnis: $projectPath" -ForegroundColor Green

# Schritt 3: README.md erstellen
Write-Host "Schritt 3: README.md erstellen..." -ForegroundColor Yellow
"# ahmad-insta" | Out-File -FilePath "README.md" -Encoding utf8
Write-Host "✓ README.md erstellt" -ForegroundColor Green

# Schritt 4: Git Repository initialisieren
Write-Host "Schritt 4: Git Repository initialisieren..." -ForegroundColor Yellow
try {
    git init
    Write-Host "✓ Git Repository initialisiert" -ForegroundColor Green
} catch {
    Write-Host "❌ Git init fehlgeschlagen" -ForegroundColor Red
    Read-Host "Drücke Enter zum Beenden"
    exit
}

# Schritt 5: Alle Dateien hinzufügen
Write-Host "Schritt 5: Dateien zu Git hinzufügen..." -ForegroundColor Yellow
git add .
Write-Host "✓ Alle Dateien hinzugefügt" -ForegroundColor Green

# Schritt 6: Ersten Commit erstellen
Write-Host "Schritt 6: Ersten Commit erstellen..." -ForegroundColor Yellow
git commit -m "first commit"
Write-Host "✓ Erster Commit erstellt" -ForegroundColor Green

# Schritt 7: Branch auf main setzen
Write-Host "Schritt 7: Branch auf main setzen..." -ForegroundColor Yellow
git branch -M main
Write-Host "✓ Branch ist main" -ForegroundColor Green

# Schritt 8: Remote Origin hinzufügen
Write-Host "Schritt 8: GitHub Repository verbinden..." -ForegroundColor Yellow
try {
    git remote add origin https://github.com/Ahmad7-7/ahmad-insta.git
    Write-Host "✓ Remote Origin hinzugefügt" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Remote Origin existiert bereits, aktualisiere..." -ForegroundColor Yellow
    git remote set-url origin https://github.com/Ahmad7-7/ahmad-insta.git
    Write-Host "✓ Remote Origin aktualisiert" -ForegroundColor Green
}

# Schritt 9: Zu GitHub pushen
Write-Host "Schritt 9: Upload zu GitHub..." -ForegroundColor Yellow
Write-Host "⚠️  WICHTIG: Stelle sicher, dass das Repository auf GitHub existiert!" -ForegroundColor Red
Write-Host "Repository URL: https://github.com/Ahmad7-7/ahmad-insta" -ForegroundColor Cyan
Write-Host ""

try {
    git push -u origin main
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✅ SUCCESS! Projekt hochgeladen!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "Dein Projekt ist verfügbar unter:" -ForegroundColor Cyan
    Write-Host "https://github.com/Ahmad7-7/ahmad-insta" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Upload fehlgeschlagen!" -ForegroundColor Red
    Write-Host "Mögliche Lösungen:" -ForegroundColor Yellow
    Write-Host "1. Repository auf GitHub erstellen: https://github.com/new" -ForegroundColor White
    Write-Host "2. GitHub Authentifizierung prüfen" -ForegroundColor White
    Write-Host "3. Personal Access Token verwenden" -ForegroundColor White
}

Write-Host ""
Read-Host "Drücke Enter zum Beenden"