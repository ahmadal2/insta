#!/bin/bash

echo "========================================"
echo "    AHMAD-INSTA GITHUB UPLOAD"
echo "========================================"
echo ""

# Zum Projektverzeichnis wechseln
cd "/c/Users/ahmed/Downloads/My Projects/ahmad-insta/ahmad-insta"
echo "✓ Verzeichnis: $(pwd)"

# Schritt 1: README.md erstellen
echo ""
echo "Schritt 1: README.md erstellen..."
echo "# ahmad-insta" >> README.md
echo "✓ README.md erstellt"

# Schritt 2: Git Repository initialisieren
echo ""
echo "Schritt 2: Git Repository initialisieren..."
git init
echo "✓ Git Repository initialisiert"

# Schritt 3: README.md zu Git hinzufügen
echo ""
echo "Schritt 3: README.md zu Git hinzufügen..."
git add README.md
echo "✓ README.md hinzugefügt"

# Schritt 4: Ersten Commit erstellen
echo ""
echo "Schritt 4: Ersten Commit erstellen..."
git commit -m "first commit"
echo "✓ Erster Commit erstellt"

# Schritt 5: Branch auf main setzen
echo ""
echo "Schritt 5: Branch auf main setzen..."
git branch -M main
echo "✓ Branch ist main"

# Schritt 6: Remote Origin hinzufügen/aktualisieren
echo ""
echo "Schritt 6: GitHub Repository verbinden..."
git remote rm origin 2>/dev/null
git remote add origin https://github.com/Ahmad7-7/ahmad-insta.git
echo "✓ Remote Origin konfiguriert"

# Schritt 7: Zu GitHub pushen
echo ""
echo "Schritt 7: Upload zu GitHub..."
echo "⚠️  WICHTIG: Repository muss auf GitHub existieren!"
echo "Repository URL: https://github.com/Ahmad7-7/ahmad-insta"
echo ""

if git push -u origin main; then
    echo ""
    echo "========================================"
    echo "✅ SUCCESS! Projekt hochgeladen!"
    echo "========================================"
    echo "Dein Projekt ist verfügbar unter:"
    echo "https://github.com/Ahmad7-7/ahmad-insta"
else
    echo ""
    echo "❌ Upload fehlgeschlagen!"
    echo "Mögliche Lösungen:"
    echo "1. Repository auf GitHub erstellen: https://github.com/new"
    echo "2. GitHub Authentifizierung prüfen"
    echo "3. Personal Access Token verwenden"
fi

echo ""
read -p "Drücke Enter zum Beenden..."