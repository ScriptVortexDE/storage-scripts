# Contributing Guide

Vielen Dank für dein Interesse an den Darkmatter IT Storage Scripts! 🎉

Beiträge sind willkommen und werden sehr geschätzt. Dieses Dokument gibt dir Richtlinien, wie du beitragen kannst.

---

## 📋 Code of Conduct

Bitte sei respektvoll und konstruktiv in all deinen Interaktionen. Wir haben keine Toleranz für:
- Beleidigungen oder Diskriminierung
- Harassment von jeglicher Art
- Spam oder Werbung

---

## 🐛 Bug Reports

### Vor dem Melden eines Bugs

- Überprüfe die [bestehenden Issues](../../issues)
- Lese die Dokumentation und [Troubleshooting Guide](./mount-size/TROUBLESHOOTING.md)
- Versuche das Problem zu reproduzieren

### Bug Report Vorlage

```markdown
## Bug Beschreibung
[Kurze Beschreibung des Bugs]

## Reproduzierungsschritte
1. Schritt 1
2. Schritt 2
3. ...

## Erwartetes Verhalten
[Was hätte passieren sollen?]

## Aktuelles Verhalten
[Was ist tatsächlich passiert?]

## Umgebung
- OS: [z.B. Ubuntu 22.04]
- Bash Version: [z.B. 5.1.16]
- Script Version: [z.B. 1.0]

## Zusätzliche Infos
[Logs, Screenshots, etc.]
```

---

## ✨ Feature Requests

### Neue Features vorschlagen

1. Überprüfe die [Roadmap](README.md#-roadmap)
2. Prüfe ob bereits ähnliche Issues existieren
3. Öffne ein neues Issue mit dem Label `enhancement`

### Feature Request Vorlage

```markdown
## Feature Beschreibung
[Was soll das Feature machen?]

## Use Case
[Warum brauchst du dieses Feature?]

## Vorschlag
[Wie könnte es implementiert werden?]

## Alternativen
[Gibt es andere Lösungsansätze?]
```

---

## 🔧 Code Contributions

### Setup für Entwicklung

```bash
# 1. Repository forken
# https://github.com/yourusername/darkmatter-storage-scripts/fork

# 2. Clonen
git clone https://github.com/yourusername/darkmatter-storage-scripts.git
cd darkmatter-storage-scripts

# 3. Feature Branch erstellen
git checkout -b feature/my-amazing-feature

# 4. Abhängigkeiten installieren
chmod +x mount-size.sh lvm-manage.sh
```

### Coding Standards

#### Bash Coding Style

```bash
# ✅ DO: Descriptive variable names
DEVICE_NAME="/dev/sdc"
MOUNT_POINT="/backup/data"

# ❌ DON'T: Single character variables
d="/dev/sdc"
m="/backup/data"

# ✅ DO: Comment complex logic
# Calculate disk space percentage
percent=$((used_space * 100 / total_space))

# ✅ DO: Error handling
if [[ $? -ne 0 ]]; then
    log_error "Operation failed!"
    exit 1
fi

# ❌ DON'T: Ignore errors
some_command
next_command  # Might fail if previous command failed
```

#### Best Practices

1. **Vermeide hardcodierte Pfade**
   ```bash
   # ✅ DO: Use variables
   TRACKING_FILE="${TRACKING_DIR}/.vg-tracking"
   
   # ❌ DON'T: Hardcode paths
   TRACKING_FILE="/var/lib/lvm-manage/.vg-tracking"
   ```

2. **Immer Input validieren**
   ```bash
   # ✅ DO: Validate input
   if [[ -z "$VG_NAME" ]]; then
       log_error "VG Name erforderlich!"
       exit 1
   fi
   ```

3. **Hilfreich Logging**
   ```bash
   # ✅ DO: Provide context
   log_info "Erstelle Partition ${PARTITION_NAME}..."
   
   # ❌ DON'T: Vague messages
   log_info "Creating..."
   ```

4. **Sicherheit beachten**
   ```bash
   # ✅ DO: Quote variables
   mount "$DEVICE" "$MOUNT_POINT"
   
   # ❌ DON'T: Unquoted variables
   mount $DEVICE $MOUNT_POINT
   ```

### Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/awesome-feature
   ```

2. **Make Changes**
   - Teste deine Änderungen gründlich
   - Schreibe aussagekräftige Commit Messages
   - Halte dich an die Coding Standards

3. **Test**
   ```bash
   # Test auf deiner lokalen Maschine
   sudo ./mount-size.sh -h
   sudo ./lvm-manage.sh -h
   
   # Führe echte Tests durch
   sudo ./mount-size.sh -m /test/mount -d /dev/test -s 100G
   ```

4. **Commit & Push**
   ```bash
   git add .
   git commit -m "Add awesome feature"
   git push origin feature/awesome-feature
   ```

5. **Pull Request**
   - Gehe zu GitHub und öffne einen Pull Request
   - Beschreibe deine Änderungen detailliert
   - Referenziere verwandte Issues (z.B. Fixes #123)

---

## 📝 Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: Neue Feature
- `fix`: Bug Fix
- `docs`: Dokumentation
- `style`: Formatierung
- `refactor`: Code-Umstrukturierung
- `test`: Tests hinzufügen
- `chore`: Build, Dependencies

### Beispiele

```
feat(lvm-manage): add snapshot functionality

- Implement LV snapshots
- Add snapshot list command
- Add snapshot delete command

Fixes #456
```

```
fix(mount-size): handle large disk names

- Fixed issue with long device names
- Added proper string escaping

Closes #123
```

---

## 📚 Documentation

Wenn du Code änderst, aktualisiere auch die Dokumentation:

1. **README.md** - Hauptdokumentation
2. **mount-size/README.md** - Script-spezifische Docs
3. **lvm-manage/README.md** - Script-spezifische Docs
4. **EXAMPLES.md** - Praktische Beispiele
5. **TROUBLESHOOTING.md** - Fehlerbehandlung

### Documentation Checklist

- [ ] Neue Features dokumentiert?
- [ ] Neue Parameter erklärt?
- [ ] Beispiele hinzugefügt?
- [ ] Links aktualisiert?
- [ ] Typos korrigiert?

---

## 🧪 Testing

### Lokale Tests

```bash
# Test mount-size.sh
sudo ./mount-size.sh -h
sudo ./mount-size.sh create-vg -d /dev/test

# Test lvm-manage.sh
sudo ./lvm-manage.sh -h
sudo ./lvm-manage.sh status
```

### Test auf verschiedenen Systemen

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Debian 10
- Debian 11
- Debian 12

### Test Cases

```bash
# mount-size.sh
- [ ] Partition mit verschiedenen Größen erstellen
- [ ] Verschiedene Dateisysteme testen
- [ ] Fehlerbehandlung testen
- [ ] Mehrere Partitionen nacheinander

# lvm-manage.sh
- [ ] VG erstellen/löschen
- [ ] LV erstellen/resize/shrink
- [ ] Status und Stats überprüfen
- [ ] Fehlerbehandlung testen
```

---

## 🔒 Security

### Sicherheitsrichtlinien

1. **Keine Secrets committen**
   - SSH Keys
   - Passwörter
   - API Keys

2. **Validiere alle Inputs**
   - User Input
   - Device Namen
   - Pfade

3. **Beachte Permissions**
   - Scripts erfordern root/sudo
   - Schütze sensitive Pfade
   - Verwende sichere Defaults

4. **Logging**
   - Keine Secrets in Logs
   - Aussagekräftige Error Messages
   - Debug Info sparsam verwenden

---

## 📦 Release Process

### Vorbereitung

1. Update CHANGELOG.md
2. Bump Version (vX.Y.Z)
3. Update README mit neuen Features
4. Commit und Tag erstellen

```bash
git tag -a v1.1.0 -m "Version 1.1.0"
git push origin v1.1.0
```

---

## 🤝 Community

### Discord/Chat Channels

- 💬 [GitHub Discussions](../../discussions)
- 📧 Email: hi@darkmatter-it.de

### Community Guidelines

- Sei respektvoll
- Helfe anderen
- Teile dein Wissen
- Stelle konstruktive Fragen

---

## ❓ Fragen?

Wenn du Fragen hast:

1. Überprüfe die Dokumentation
2. Suche in bestehenden Issues
3. Öffne ein neues Issue mit Label `question`
4. Kontaktiere das Team: info@darkmatter-it.de

---

## 🙏 Danke!

Danke dass du diese Projekt verbessert! Deine Beiträge machen den Unterschied.

---

**Happy Contributing!** 🎉
