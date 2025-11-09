# lvm-manage.sh - Praktische Beispiele

Detaillierte Beispiele für verschiedene Anwendungsszenarien mit LVM.

---

## 🎯 Basis Beispiele

### Beispiel 1: Erste Schritte

**Szenario:** Neue 16TB Disk, erstes LVM Setup

```bash
# 1. Überprüfe verfügbare Disks
lsblk
# Output: sde  8:64    0  16T  0 disk

# 2. Erstelle Volume Group (einmalig)
sudo ./lvm-manage.sh create-vg -d /dev/sde -vg backup-pool

# 3. Überprüfe VG
sudo ./lvm-manage.sh status --vgn backup-pool

# 4. Erstelle erstes Logical Volume (1000GB)
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv kunde-001 -s 1000G -m /backup/kunde-001

# 5. Überprüfe LV
df -h /backup/kunde-001
sudo ./lvm-manage.sh stats -vg backup-pool
```

---

### Beispiel 2: Mehrere Kunden hinzufügen

**Szenario:** 5 neue Kunden mit unterschiedlichen Größen

```bash
# Kunde A: 2000GB (großer Kunde)
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv kunde-a -s 2000G -m /backup/kunde-a

# Kunde B: 1500GB (mittelgroßer Kunde)
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv kunde-b -s 1500G -m /backup/kunde-b

# Kunde C: 1000GB (Standard Kunde)
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv kunde-c -s 1000G -m /backup/kunde-c

# Kunde D: 750GB (kleiner Kunde)
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv kunde-d -s 750G -m /backup/kunde-d

# Kunde E: 500GB (minimal Kunde)
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv kunde-e -s 500G -m /backup/kunde-e

# Überblick
sudo ./lvm-manage.sh stats -vg backup-pool
```

**Ergebnis:**
```
=== LVM Statistiken ===

Name                      Größe           Genutzt         %
────────────────────────────────────────────────────────
kunde-a                   2000.00 GiB     100G            5%
kunde-b                   1500.00 GiB     200G            13%
kunde-c                   1000.00 GiB     50G             5%
kunde-d                   750.00 GiB      30G             4%
kunde-e                   500.00 GiB      10G             2%

Freier Speicher: 9.5TB verfügbar!
```

---

## 💼 Production Beispiele

### Beispiel 3: Kundenupgrade ohne Ausfallzeit

**Szenario:** Kunde braucht plötzlich mehr Speicher (Online!)

```bash
# Aktueller Status
sudo ./lvm-manage.sh stats -vg backup-pool
# kunde-a: 1000G mit 800G Daten (80% voll)

# Kunde möchte upgraden auf 2000G
# ⏸️ KEIN Neustart erforderlich!
# ⏸️ KEINE Ausfallzeit!

sudo ./lvm-manage.sh resize-lv -vg backup-pool -lv kunde-a -s 2000G

# Sofort verfügbar
df -h /backup/kunde-a
# /backup/kunde-a  2000G  800G  1200G  40% (statt 80%!)

# Kunde hat wieder Platz und weiß nichts von Downtime (es gibt keine!)
```

---

### Beispiel 4: Tiered Storage

**Szenario:** 3 verschiedene Performance-Tiers mit LVM

```bash
# Performance Tier (SSD)
sudo ./lvm-manage.sh create-vg -d /dev/nvme0n1 -vg ssd-tier
sudo ./lvm-manage.sh create-lv -vg ssd-tier -lv premium-customers -s 500G -m /backup/premium

# Standard Tier (SATA)
sudo ./lvm-manage.sh create-vg -d /dev/sdb -vg sata-tier
sudo ./lvm-manage.sh create-lv -vg sata-tier -lv standard-customers -s 5000G -m /backup/standard

# Archive Tier (Großraum HDD)
sudo ./lvm-manage.sh create-vg -d /dev/sdc -vg archive-tier
sudo ./lvm-manage.sh create-lv -vg archive-tier -lv archive-customers -s 20000G -m /backup/archive

# Kunden entsprechend verteilen
# Premium: SSD (schnelle Backups)
# Standard: SATA (gutes Balance)
# Archive: Großraum (Langzeit Lagern)
```

---

### Beispiel 5: Automatisches Monitoring

**Szenario:** Tägliche Überwachung mit Alerts

```bash
#!/bin/bash
# File: /usr/local/bin/lvm-monitor.sh

echo "=== LVM Monitoring $(date) ===" > /tmp/lvm-report.txt

# Status
echo "Backup Pool Status:" >> /tmp/lvm-report.txt
sudo /usr/local/bin/lvm-manage stats -vg backup-pool >> /tmp/lvm-report.txt

# Alert bei 80% Auslastung
echo "" >> /tmp/lvm-report.txt
echo "Volumes über 80%:" >> /tmp/lvm-report.txt
sudo /usr/local/bin/lvm-manage stats -vg backup-pool | grep -E "[8-9][0-9]%|100%" >> /tmp/lvm-report.txt

# Email Report
mail -s "Daily LVM Report" admin@example.com < /tmp/lvm-report.txt
```

**Cron Setup:**
```bash
# Täglich um 2 Uhr
0 2 * * * /usr/local/bin/lvm-monitor.sh
```

---

## 📈 Skalierungs Beispiele

### Beispiel 6: Von 12TB auf 28TB erweitern

**Szenario:** Disk voll, neue große Disk hinzufügen

```bash
# Aktueller Status
lsblk
# sde: 16TB (fast voll)

# Neue Disk installiert
lsblk
# sde: 16TB (alt)
# sdf: 12TB (neu)

# Alte VG ist voll
sudo vgdisplay backup-pool | grep Free
# Free PE / Size       100 / 2.00 GiB  (sehr wenig!)

# Neue Disk zur VG hinzufügen
sudo ./lvm-manage.sh expand-vg -d /dev/sdf -vg backup-pool

# Jetzt viel Platz!
sudo vgdisplay backup-pool | grep "VG Size"
# VG Size                28.00 TiB

# Neue Kunden können bedient werden
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv neue-kunde -s 2000G -m /backup/neue-kunde
```

---

### Beispiel 7: Mehrere Volume Groups

**Szenario:** Trennung nach Kundentyp

```bash
# Enterprise VG (High Performance)
sudo ./lvm-manage.sh create-vg -d /dev/sdb -vg enterprise-backups
sudo ./lvm-manage.sh create-lv -vg enterprise-backups -lv fortune-500 -s 5000G -m /backup/enterprise/fortune-500
sudo ./lvm-manage.sh create-lv -vg enterprise-backups -lv tech-startup -s 3000G -m /backup/enterprise/tech-startup

# SMB VG (Standard)
sudo ./lvm-manage.sh create-vg -d /dev/sdc -vg smb-backups
sudo ./lvm-manage.sh create-lv -vg smb-backups -lv shop-001 -s 500G -m /backup/smb/shop-001
sudo ./lvm-manage.sh create-lv -vg smb-backups -lv office-002 -s 750G -m /backup/smb/office-002

# Startup VG (Budget)
sudo ./lvm-manage.sh create-vg -d /dev/sdd -vg startup-backups
sudo ./lvm-manage.sh create-lv -vg startup-backups -lv startup-001 -s 250G -m /backup/startup/startup-001

# Überblick aller VGs
sudo ./lvm-manage.sh status --all
```

---

## 🔄 Lifecycle Beispiele

### Beispiel 8: Kunde upgradet & downgradet

**Szenario:** Dynamische Größenänderungen

```bash
# Tag 1: Kunde mietet 1000G
sudo ./lvm-manage.sh create-lv -vg backup-pool -lv acme-corp -s 1000G -m /backup/acme-corp
echo "Acme Corp startet mit 1000GB"

# Tag 30: Kunde wächst, braucht mehr
echo "Acme Corp wächst auf 2000GB"
sudo ./lvm-manage.sh resize-lv -vg backup-pool -lv acme-corp -s 2000G

# Tag 60: Kunde optimiert, braucht weniger
# (Nachdem Daten gelöscht wurden)
echo "Acme Corp reduziert auf 1500GB"
sudo ./lvm-manage.sh shrink-lv -vg backup-pool -lv acme-corp -s 1500G

# Tag 90: Kunde kündigt
echo "Acme Corp kündigt"
sudo ./lvm-manage.sh delete-lv -vg backup-pool -lv acme-corp

# Speicher ist wieder frei für nächsten Kunden!
```

---

### Beispiel 9: Kunde migriert zu anderem Provider

**Szenario:** Daten exportieren, Volume löschen

```bash
# 1. Backup vor Löschung (zur Sicherheit)
sudo tar -czf /archive/acme-corp-backup-$(date +%Y%m%d).tar.gz /backup/acme-corp/

# 2. Kunde hat Daten geholt
echo "Kunde bestätigt Datenabzug"

# 3. Lösche Volume
sudo ./lvm-manage.sh delete-lv -vg backup-pool -lv acme-corp

# 4. Überblick verfügbarer Speicher
sudo ./lvm-manage.sh stats -vg backup-pool

# Speicher frei für nächsten Kunden!
```

---

## 🆘 Troubleshooting Beispiele

### Beispiel 10: Volume wird nicht angezeigt in stats

**Szenario:** Debugging von fehlenden Volumes

```bash
# Problem: stats zeigt volume nicht
sudo ./lvm-manage.sh stats -vg backup-pool
# → Volume fehlt in der Liste

# Debug: Überprüfe fstab
cat /etc/fstab | grep backup-pool
# → Keine Einträge oder fehlerhafte UUIDs

# Fix: Manuell überprüfen
sudo blkid | grep backup-pool
# UUID=xxx /dev/backup-pool/missing

# Fix: Mountpoint erstellen und mounten
sudo mkdir -p /backup/missing-volume
sudo mount /dev/backup-pool/missing-volume /backup/missing-volume

# Fix: Zu fstab hinzufügen
sudo nano /etc/fstab
# Hinzufügen: UUID=xxx /backup/missing-volume ext4 defaults,nofail 0 2

# Reload fstab
sudo mount -a

# Jetzt sollte es in stats angezeigt werden!
```

---

### Beispiel 11: VG ist fast voll (90%)

**Szenario:** Platz läuft aus, muss schnell gelöst werden

```bash
# 1. Überprüfe aktuellen Status
sudo vgdisplay backup-pool | grep -E "VG Size|Free"
# VG Size: 16.00 TiB
# Free: 1.5 TiB (9%)

# 2. Überprüfe welche LVs voll sind
sudo ./lvm-manage.sh stats -vg backup-pool
# → Sehe welche LVs voll sind

# 3. Optionen:
# Option A: Neue Disk hinzufügen (beste Lösung)
sudo ./lvm-manage.sh expand-vg -d /dev/sdf -vg backup-pool

# Option B: Alte Daten löschen
sudo ./lvm-manage.sh delete-lv -vg backup-pool -lv old-inactive-customer

# Option C: Kunde upgraden zu weniger genutztem Volume
sudo ./lvm-manage.sh resize-lv -vg backup-pool -lv große-lv -s 15000G  # Verkleinern

# Nach einer Option:
sudo ./lvm-manage.sh stats -vg backup-pool
# → Sollte wieder genug Platz haben
```

---

## 📊 Reporting Beispiele

### Beispiel 12: Kapazitäts-Report für Management

**Szenario:** Monatlicher Report über Auslastung

```bash
#!/bin/bash
# File: monthly-capacity-report.sh

REPORT_FILE="/var/log/capacity-report-$(date +%Y-%m).txt"

echo "=== Monthly Capacity Report $(date +%B) ===" > $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Overall Stats
echo "Overall Statistics:" >> $REPORT_FILE
sudo vgdisplay backup-pool | grep -E "VG Size|Free" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Per Customer Stats
echo "Per Customer Usage:" >> $REPORT_FILE
sudo ./lvm-manage.sh stats -vg backup-pool >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Trend Analysis
echo "Growth Trend:" >> $REPORT_FILE
echo "Last Month Used: $(tail -1 /var/log/capacity-report-$(date -d 'last month' +%Y-%m).txt 2>/dev/null | awk '{print $NF}')" >> $REPORT_FILE
echo "This Month Used: $(sudo ./lvm-manage.sh stats -vg backup-pool 2>/dev/null | grep "%" | awk '{sum+=$NF} END {print sum/NR}')" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Recommendations
echo "Recommendations:" >> $REPORT_FILE
FREE_SPACE=$(sudo vgdisplay backup-pool | grep "Free" | awk '{print $NF}')
if [[ ${FREE_SPACE%.*} -lt 2 ]]; then
    echo "⚠️ ALERT: Less than 2TB free! Consider expanding storage." >> $REPORT_FILE
fi

# Email Report
mail -s "Monthly Capacity Report $(date +%B)" management@company.com < $REPORT_FILE
```

**Cron Setup:**
```bash
# Letzte Tag des Monats um 18 Uhr
0 18 28-31 * * test $(date -d tomorrow +%d) -eq 01 && /usr/local/bin/monthly-capacity-report.sh
```

---

### Beispiel 13: Chargeback Report (Wer zahlt was)

**Szenario:** Berechnung der Kosten pro Kunde

```bash
#!/bin/bash
# File: chargeback-report.sh

COST_PER_TB=100  # Dollar pro TB pro Monat

echo "=== Chargeback Report ===" > /tmp/chargeback.txt
echo "Pricing: \$$COST_PER_TB per TB/month" >> /tmp/chargeback.txt
echo "" >> /tmp/chargeback.txt

sudo ./lvm-manage.sh stats -vg backup-pool | grep -v "===" | tail -n +3 | while read line; do
    NAME=$(echo "$line" | awk '{print $1}')
    SIZE=$(echo "$line" | awk '{print $2}' | sed 's/GiB//' | awk '{printf "%.2f\n", $1/1024}')  # Convert to TB
    COST=$(echo "$SIZE * $COST_PER_TB" | bc)
    
    echo "$NAME: ${SIZE}TB = \$$COST" >> /tmp/chargeback.txt
done

mail -s "Monthly Chargeback Report" billing@company.com < /tmp/chargeback.txt
```

---

## 🚀 Advanced Beispiele

### Beispiel 14: Automatisches Backup Script mit LVM

**Szenario:** Automatische tägliche Backups mit Snapshot

```bash
#!/bin/bash
# File: automated-backup.sh

BACKUP_DATE=$(date +%Y%m%d)
VG_NAME="backup-pool"

# Backup Funktion (später mit Snapshots erweitert)
backup_volume() {
    local LV_NAME=$1
    local BACKUP_PATH="/archive/backups/${LV_NAME}_${BACKUP_DATE}.tar.gz"
    
    echo "Backing up $LV_NAME..."
    sudo tar -czf $BACKUP_PATH /backup/$LV_NAME/
    
    # Überprüfe Größe
    BACKUP_SIZE=$(du -sh $BACKUP_PATH | awk '{print $1}')
    echo "$LV_NAME backed up: $BACKUP_SIZE"
}

# Alle LVs durchgehen
sudo lvdisplay /dev/$VG_NAME | grep "LV Path" | awk '{print $NF}' | while read lv; do
    LV_NAME=$(basename $lv)
    backup_volume $LV_NAME
done

echo "All backups completed!"
```

---

### Beispiel 15: Geschwindigkeit Vergleich

**Szenario:** Performance Benchmark verschiedener Setups

```bash
#!/bin/bash
# File: performance-test.sh

echo "=== LVM Performance Test ===" > /tmp/perf-test.txt

# Test Write Speed
echo "Write Speed Test:" >> /tmp/perf-test.txt
dd if=/dev/zero of=/backup/kunde-001/testfile bs=1M count=1000 2>&1 | grep -E "bytes|copied" >> /tmp/perf-test.txt

# Test Read Speed
echo "Read Speed Test:" >> /tmp/perf-test.txt
dd if=/backup/kunde-001/testfile of=/dev/null bs=1M 2>&1 | grep -E "bytes|copied" >> /tmp/perf-test.txt

# Test Resize Performance
echo "Resize Performance:" >> /tmp/perf-test.txt
time sudo ./lvm-manage.sh resize-lv -vg backup-pool -lv kunde-001 -s 2000G >> /tmp/perf-test.txt

cat /tmp/perf-test.txt
```

---

## 💡 Best Practices

### Beispiel 16: Produktions-Checkliste

```bash
#!/bin/bash
# Vor dem Go-Live durchgehen

echo "=== Production Readiness Checklist ==="

# 1. Storage Capacity
echo "[1] Storage Capacity:"
sudo vgdisplay backup-pool | grep "VG Size"
echo "✓ Minimum 20% free space required"

# 2. Backup Configuration
echo "[2] Backup Configuration:"
ls -la /backup/
echo "✓ All customer volumes mounted"

# 3. Monitoring Setup
echo "[3] Monitoring Setup:"
crontab -l | grep "lvm-monitor"
echo "✓ Automated monitoring enabled"

# 4. Disaster Recovery
echo "[4] Disaster Recovery:"
echo "✓ Backup of /etc/fstab exists"
ls -la /backup/etc-fstab-backup*

# 5. Documentation
echo "[5] Documentation:"
echo "✓ Runbooks prepared"
echo "✓ Escalation procedures defined"

echo ""
echo "=== Ready for Production ==="
```

---

**Weitere Fragen? Siehe [README.md](./README.md) oder [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**
