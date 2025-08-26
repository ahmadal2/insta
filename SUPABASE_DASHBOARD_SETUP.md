# Supabase Dashboard Setup - Storage Fix

## ERROR: "must be owner of table objects" - LÖSUNG

Da Sie keine Berechtigung haben, Storage-Policies zu erstellen, müssen wir einen anderen Ansatz verwenden.

## 🔧 **SCHRITT-FÜR-SCHRITT LÖSUNG:**

### **Schritt 1: SQL Script ausführen (Nur Database Policies)**

1. **Gehen Sie zu Supabase Dashboard** → SQL Editor
2. **Führen Sie nur das `storage_fix_without_policies.sql` Script aus**
3. **Dieses Script repariert nur die Posts-Tabelle** (keine Storage-Policies)

### **Schritt 2: Storage Bucket über Dashboard konfigurieren**

1. **Gehen Sie zu "Storage"** in Ihrem Supabase Dashboard
2. **Klicken Sie "Create new bucket"**
3. **Bucket Name**: `images` (exakt so)
4. **WICHTIG**: ✅ **"Public bucket" aktivieren**
5. **File size limit**: 50MB
6. **Allowed MIME types**: `image/*`
7. **Klicken Sie "Create bucket"**

### **Schritt 3: Bucket Policies über Dashboard setzen**

1. **Klicken Sie auf den "images" bucket**
2. **Gehen Sie zu "Policies" Tab**
3. **Klicken Sie "New Policy"**
4. **Template wählen**: "Allow public read access"
5. **Klicken Sie "Use this template"**
6. **Policy Name**: `public_read_images`
7. **Klicken Sie "Save policy"**

### **Schritt 4: Upload Policy hinzufügen**

1. **Wieder "New Policy" klicken**
2. **Template wählen**: "Allow authenticated uploads"
3. **Policy Name**: `authenticated_upload_images`
4. **Target roles**: `authenticated`
5. **Klicken Sie "Save policy"**

### **Schritt 5: Alternative - Bucket Public machen**

Falls die Policies nicht funktionieren:

1. **Gehen Sie zu Storage → Settings**
2. **Finden Sie den "images" bucket**
3. **Klicken Sie auf Settings (⚙️ Icon)**
4. **Aktivieren Sie "Public bucket"**
5. **Klicken Sie "Save"**

## ✅ **Überprüfung:**

Nach diesen Schritten:

### **Test 1: Bucket ist sichtbar**
- Gehen Sie zu Storage → images
- Sie sollten den Bucket sehen können

### **Test 2: Upload Test**
- Versuchen Sie einen Upload in Ihrer App
- Nutzen Sie die `/debug` Seite um zu testen

### **Test 3: SQL Überprüfung**
```sql
-- Überprüfen Sie, dass der Bucket existiert
SELECT * FROM storage.buckets WHERE name = 'images';

-- Überprüfen Sie Posts Policies
SELECT policyname FROM pg_policies WHERE tablename = 'posts';
```

## 🚨 **Falls immer noch Probleme:**

### **Temporäre Lösung:**
Wenn Storage-Uploads immer noch fehlschlagen, können Sie temporarily RLS für Storage komplett deaktivieren:

1. **Fragen Sie Ihren Supabase Admin** um diesen Befehl auszuführen:
```sql
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
```

⚠️ **ACHTUNG**: Dies ist nur für Development/Testing!

### **Langfristige Lösung:**
- **Bitten Sie einen Supabase Project Owner** die Storage Policies zu setzen
- **Oder nutzen Sie einen Service Account** mit Owner-Rechten

## 📞 **Support:**

Falls nichts funktioniert:
1. Nutzen Sie die `/debug` Seite in Ihrer App
2. Überprüfen Sie Browser Console für detaillierte Fehlermeldungen
3. Stellen Sie sicher, dass Sie als Project Owner angemeldet sind

Der wichtigste Punkt ist, dass der **Bucket "public" sein muss** und **"images" heißen muss**.