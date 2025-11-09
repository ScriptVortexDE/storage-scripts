# FAQ - Häufig Gestellte Fragen

Antworten auf die häufigsten Fragen zu den Darkmatter IT Storage Scripts.

---

## 📦 mount-size.sh

### F: Was ist der Unterschied zwischen GPT und MBR?

**A:** 
- **MBR**: Altes Format, max 2TB pro Partition
- **GPT**: Modernes Format, praktisch unbegrenzte Größen

Dieses Script nutzt GPT automatisch, ideal für große moderne Disks.

---

### F: Kann ich eine Partition später vergrößern?

**A:** Nein, mit `mount-size.sh` nicht. Dafür brauchst du:
- `lvm-manage.sh` für flexible Resizing
- Oder neue Partition erstellen, Daten verschieben

---

### F: Wie viele Partitionen kann ich pro Disk erstellen?

**A:** Mit GPT theoretisch unbegrenzt. Praktisch empfohlen:
- **Optimal**: 3-5 Partitionen
- **Maximum**: 10-20 Partitionen
- Mehr wird schwer verwaltbar

---

### F: Kann ich verschiedene Dateisysteme verwenden?

**A:** Ja!

```bash
# ext4 (default)
./mount-size.sh -m /part/data -d /dev/sdc -s 1000G

# XFS
./mount-size.sh -m /part/data -d /dev/sdc -s 1000G -t xfs

# btrfs
./mount-size.sh -m /part/data -d /dev/sdc -s 1000G -t btrfs
```

---

### F: Was passiert wenn ich --wipe-disk nutze?

**A:** 
- ✅ Alle Partitionen auf der Disk werden gelöscht
- ✅ Disk wird neu initialisiert mit GPT
- ✅ Schnell (~Sekunden)
- ⚠️ ALLE DATEN SIND WEG!

---

### F: Wie lange dauert --wipe-all?

**A:** SEHR LANGE!
- 1TB Disk: ~20 Minuten
- 10TB Disk: 2-3 Stunden
- 12TB Disk: 2-4 Stunden

Nutze nur wenn wirklich nötig!

---

### F: Kann ich mehrere Disks gleichzeitig partitionieren?

**A:** Ja, aber **SERIELL** (nacheinander), nicht parallel:

```bash
# ✅ RICHTIG
./mount-size.sh -m /part/d1 -d /dev/sdc -s 1000G
./mount-size.sh -m /part/d2 -d /dev/sdd -s 1000G

# ❌ FALSCH - Don't parallel
./mount-size.sh -m /part/d1 -d /dev/sdc -s 1000G &
./mount-size.sh -m /part/d2 -d /dev/sdd -s 1000G &
```

---

### F: Wie überprüfe ich ob alles richtig eingebunden ist?

**A:**
```bash
# Alle Partitionen anzeigen
lsblk

# Speichernutzung überprüfen
df -h

# Spezifische Partition überprüfen
df -h /part/data
```

---

## 📦 lvm-manage.sh

### F: Was ist LVM und warum sollte ich es nutzen?

**A:** LVM (Logical Volume Manager) bietet:
- ✅ Flexible Größenänderung ohne Ausfallzeit
- ✅ Snapshots & Clones
- ✅ Striping & Mirroring
- ✅ Besser für Production Systeme

---

### F: Was ist der Unterschied zwischen VG und LV?

**A:**
- **VG (Volume Group)**: Sammlung von Disks (z.B. backup-pool = 12TB)
- **LV (Logical Volume)**: Einzelnes Volume innerhalb VG (z.B. kunde1 = 1TB)

Analogy: VG = Lagerhaus, LV = einzelne Boxen

---

### F: Wie viele LVs kann ich pro VG haben?

**A:** Praktisch unbegrenzt! Aber beachte:
- **Empfohlen**: 10-50 LVs pro VG
- **Maximum**: Techisch 255 (aber unpraktisch)

---

### F: Kann ich ein LV vergrößern ohne Ausfallzeit?

**A:** Ja! Das ist der Hauptvorteil von LVM:

```bash
# Online Resize (Daten bleiben verfügbar!)
sudo ./lvm-manage.sh resize-lv -vg backup-pool -lv kunde1 -s 1500G

# Kein Unmount, keine Ausfallzeit!
```

---

### F: Wie shrink ich ein LV?

**A:** Mit `shrink-lv`, aber VORSICHT:

```bash
# Funktioniert nur wenn weniger Daten vorhanden sind!
sudo ./lvm-manage.sh shrink-lv -vg backup-pool -lv kunde1 -s 500G

# Das Script wird fragen ob du sicher bist!
```

---

### F: Kann ich ein LV löschen?

**A:** Ja, aber vorsichtig:

```bash
# ⚠️ Löscht ALLE Daten!
sudo ./lvm-manage.sh delete-lv -vg backup-pool -lv kunde1

# Das Script fragt um Bestätigung!
```

---

### F: Was passiert wenn eine VG voll ist?

**A:** Neue LVs können nicht erstellt werden. Lösung:

```bash
# Option 1: Neue Disk hinzufügen
sudo ./lvm-manage.sh expand-vg -d /dev/sdf -vg backup-pool

# Option 2: Alte LVs löschen
sudo ./lvm-manage.sh delete-lv -vg backup-pool -lv old-customer
```

---

### F: Wie vergrößere ich eine VG?

**A:** Neue Disk hinzufügen:

```bash
# In Proxmox: Disk von 12TB auf 20TB vergrößern
# Oder neue Disk hinzufügen

# Dann im Server:
sudo ./lvm-manage.sh expand-vg -d /dev/sde -vg backup-pool

# Prüfe verfügbaren Platz
sudo vgdisplay backup-pool | grep Free
```

---

### F: Was ist das Tracking-System?

**A:** Das Script speichert alle selbst erstellten VGs in:
```
/var/lib/lvm-manage/.vg-tracking
```

Das hilft dem Script zu wissen, welche VGs du erstellt hast:
- `status` zeigt nur getracked VGs
- `status --all` zeigt ALLE VGs im System

---

### F: Kann ich manuell erstellte VGs verwalten?

**A:** Ja, aber sie werden nicht automatisch getracked. Nutze:

```bash
# Für alle VGs im System (auch manuell erstellte)
sudo ./lvm-manage.sh status --all

# Für spezifische VG
sudo ./lvm-manage.sh status --vgn my-custom-vg
```

---

### F: Wie lange dauert die Stats-Ausgabe?

**A:** 3-10 Sekunden je nach Anzahl LVs. Script zeigt "⏳ Sammle Daten..." während er arbeitet.

---

## 🔄 Vergleich & Entscheidungen

### F: Welches Script soll ich verwenden?

**A:** Kommt auf dein Szenario an:

```
mount-size.sh wenn:
- Einfaches, schnelles Setup
- Statische Größen
- Nicht häufige Änderungen
- Test/Dev Umgebung

lvm-manage.sh wenn:
- Viele Kunden
- Häufige Größenänderungen
- Production Umgebung
- Flexible Verwaltung nötig
```

---

### F: Kann ich beide Scripts kombinieren?

**A:** Ja! Hybrid-Approach:

```bash
# mount-size.sh für Grundstruktur
./mount-size.sh -m /datastore/pool1 -d /dev/sdc -s 6000G
./mount-size.sh -m /datastore/pool2 -d /dev/sdc -s 6000G

# lvm-manage.sh für Kundenverwaltung
./lvm-manage.sh create-vg -d /dev/sde -vg customer-volumes
./lvm-manage.sh create-lv -vg customer-volumes -lv kunde-01 -s 500G -m /customers/kunde-01
```

---

## 🐛 Troubleshooting

### F: "Device nicht gefunden" - Was nun?

**A:**
```bash
# Überprüfe verfügbare Devices
lsblk

# Oder prüfe spezifisch
ls -la /dev/sd*

# Device-Name kann z.B. sein: /dev/sdc, /dev/sdd, /dev/nvme0n1
```

---

### F: "Permission denied" - Was ist das Problem?

**A:** Scripts brauchen root:

```bash
# ❌ FALSCH
./mount-size.sh -m /part/data -d /dev/sdc -s 1000G

# ✅ RICHTIG
sudo ./mount-size.sh -m /part/data -d /dev/sdc -s 1000G
```

---

### F: Mount fehlgeschlagen - Was tun?

**A:**
```bash
# 1. Überprüfe ob Mountpoint existiert
sudo mkdir -p /part/data

# 2. Überprüfe fstab
cat /etc/fstab | grep sdc

# 3. Manuelle Mount versuchen
sudo mount /dev/sdc1 /part/data/

# 4. Wenn noch nicht geht: Dateisystem überprüfen
sudo fsck -n /dev/sdc1
```

---

### F: Partition wird in stats nicht angezeigt

**A:**
```bash
# 1. Überprüfe fstab
cat /etc/fstab | grep backup-pool

# 2. Sollte UUID Entry haben wie:
# UUID=... /backup/kunde1 ext4 defaults,nofail 0 2

# 3. Wenn nicht: Manuell hinzufügen
sudo blkid /dev/backup-pool/kunde1-backup
# UUID kopieren und zu fstab hinzufügen

# 4. Remount
sudo mount -a
```

---

## 🔐 Sicherheit

### F: Sind diese Scripts sicher?

**A:** Ja, mit Bedingungen:
- ✅ Input wird validiert
- ✅ Bestätigungen vor Löschen
- ⚠️ Brauchen aber root/sudo
- ⚠️ Können Daten löschen wenn Befehle falsch sind

---

### F: Kann ich diese Scripts automatisieren?

**A:** Ja, aber vorsichtig:

```bash
# ✅ SICHER: Mit Bestätigung
0 2 * * * /root/check-disk.sh | mail admin

# ❌ UNSICHER: Destruktive Befehle automatisiert
0 2 * * * sudo ./mount-size.sh --wipe-disk -d /dev/sdc
```

---

### F: Werden Secrets in Log-Dateien gespeichert?

**A:** Nein! Die Scripts speichern:
- ✅ Device-Namen
- ✅ Größen
- ✅ Mountpoints
- ❌ KEINE Passwörter/Keys
- ❌ KEINE Secrets

---

## 📊 Performance

### F: Wie schnell ist mount-size.sh?

**A:**
- Partition-Erstellung: < 1 Minute
- Formatierung: Abhängig von Größe
- Mount: < 10 Sekunden

---

### F: Wie schnell ist lvm-manage.sh?

**A:**
- VG Erstellung: < 1 Minute
- LV Erstellung: < 2 Minuten
- Resize: < 1 Minute (online!)
- Stats sammeln: 3-10 Sekunden

---

### F: Kann ich Performance optimieren?

**A:**
```bash
# Moderne Disk-Scheduling verwenden
sudo echo "mq-deadline" > /sys/block/sdc/queue/scheduler

# Performance Tuning für ext4
sudo tune2fs -O extent,flex_bg,metadata_csum /dev/sdc1

# BBR Congestion Control (falls zutreffend)
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
```

---

## 🆘 Weitere Hilfe

### Wo kann ich Hilfe bekommen?

1. **Dokumentation lesen**
   - [mount-size README](../mount-size/README.md)
   - [lvm-manage README](../lvm-manage/README.md)

2. **Troubleshooting Guides**
   - [mount-size Troubleshooting](../mount-size/TROUBLESHOOTING.md)
   - [lvm-manage Troubleshooting](../lvm-manage/TROUBLESHOOTING.md)

3. **Issues öffnen**
   - [GitHub Issues](../../issues)

4. **Kontakt**
   - 📧 hi@darkmatter-it.de
   - 🔐 Sicherheit: hi@darkmatter-it.de

---

## 💡 Tipps & Tricks

### Schnelle Disk-Übersicht

```bash
alias check-disk='lsblk && echo "---" && df -h'
check-disk  # Nutzen!
```

### LVM Stats Alias

```bash
alias lvm-stats='sudo /usr/local/bin/lvm-manage stats -vg backup-pool'
lvm-stats  # Nutzen!
```

### Automatische Backups

```bash
# Daily Backup
0 2 * * * tar -czf /backup/backup-$(date +\%Y\%m\%d).tar.gz /important/data/
```

---

**Noch Fragen? Öffne ein Issue auf GitHub!** 🎉
