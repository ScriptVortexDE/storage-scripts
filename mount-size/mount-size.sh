#!/bin/bash

# Festplatten Partition & Mount Script
# Verwendung: ./mount-size.sh -m /mnt/data -d /dev/sdf -s 100G [-t ext4]

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variablen
MOUNT_POINT=""
DEVICE=""
SIZE=""
FSTYPE="ext4"
WIPE_DISK=0
WIPE_ALL=0
FORMAT_PARTITION=0
CREATED_PARTITION=""

# Funktionen
show_help() {
    cat << 'EOF'
Verwendung: ./mount-size.sh [OPTIONS]

Partition erstellen und mounten:
  -m <path>      Mountpoint (z.B. /mnt/data/temp)
  -d <device>    Device (z.B. /dev/sdf)
  -s <size>      Partitionsgröße (z.B. 100G, 500M, 1T)
  -t <type>      Dateisystem (default: ext4, möglich: xfs, btrfs, ext3)
  --format-partition  Partition automatisch formatieren (ist Standard, nur explizit wenn nötig)

Disk löschen:
  --wipe-disk    Löscht ALLE Partitionen und initialisiert neu
  --wipe-all     Überschreibt gesamte Disk mit Nullen (SEHR langsam!)

Sonstiges:
  -h             Diese Hilfe anzeigen

Beispiele:
  ./mount-size.sh -m /mnt/data/temp -d /dev/sdf -s 100G
  ./mount-size.sh -m /mnt/data/other -d /dev/sdf -s 500G
  ./mount-size.sh -m /mnt/backup -d /dev/sdd -s 1T -t xfs
  ./mount-size.sh --wipe-disk -d /dev/sdf
  ./mount-size.sh --wipe-all -d /dev/sdf
EOF
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[SCHRITT]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Dieses Script muss als root ausgeführt werden!"
        exit 1
    fi
}

check_device_exists() {
    if [[ ! -b "$DEVICE" ]]; then
        log_error "Device $DEVICE ist kein Block Device!"
        exit 1
    fi
}

validate_size() {
    if ! [[ "$SIZE" =~ ^[0-9]+[KMGT]$ ]]; then
        log_error "Ungültige Größenangabe: $SIZE"
        log_info "Gültige Formate: 100M, 100G, 1T, etc."
        exit 1
    fi
}

get_next_partition_number() {
    local max_num=0
    local num
    
    # Finde die höchste Partitionsnummer
    for partition in ${DEVICE}*; do
        if [[ "$partition" =~ ^${DEVICE}[0-9]+$ ]]; then
            num=$(echo "$partition" | sed 's/[^0-9]*//g')
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done
    
    echo $((max_num + 1))
}

get_last_partition() {
    local max_num=0
    local num
    
    # Finde die höchste Partitionsnummer
    for partition in ${DEVICE}*; do
        if [[ "$partition" =~ ^${DEVICE}[0-9]+$ ]]; then
            num=$(echo "$partition" | sed 's/[^0-9]*//g')
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done
    
    if [[ $max_num -eq 0 ]]; then
        echo ""
    else
        echo "${DEVICE}${max_num}"
    fi
}

init_gpt_if_needed() {
    local existing_partitions
    existing_partitions=$(fdisk -l "$DEVICE" 2>/dev/null | grep -c "^$DEVICE" || true)
    
    if [[ $existing_partitions -eq 0 ]]; then
        log_info "Initialisiere GPT Partitionstabelle..."
        # Erstelle GPT Partitionstabelle
        {
            echo "g"  # GPT
            echo "w"  # speichern
        } | fdisk "$DEVICE" > /dev/null 2>&1
        sleep 2
    else
        # Checke ob es schon GPT ist
        local label_type
        label_type=$(fdisk -l "$DEVICE" | grep "Disklabel type:" | awk '{print $NF}')
        if [[ "$label_type" != "gpt" ]]; then
            log_warn "Disk hat MBR/DOS Partitionstabelle, nicht GPT!"
            log_info "Für Partitionen größer als 2TB muss GPT verwendet werden."
            read -p "Soll die Disk zu GPT konvertiert werden? (ja/nein): " convert
            if [[ "$convert" == "ja" ]]; then
                log_info "Konvertiere zu GPT..."
                {
                    echo "g"
                    echo "w"
                } | fdisk "$DEVICE" > /dev/null 2>&1
                sleep 2
            fi
        fi
    fi
}

create_partition() {
    log_step "Erstelle neue Partition mit Größe $SIZE..."
    
    local next_num
    next_num=$(get_next_partition_number)
    
    CREATED_PARTITION="${DEVICE}${next_num}"
    
    log_info "Nächste Partitionsnummer: $next_num"
    log_info "Partition wird sein: $CREATED_PARTITION"
    log_info "Größe: $SIZE"
    
    # Berechne verfügbaren Platz
    local total_sectors
    total_sectors=$(fdisk -l "$DEVICE" | grep "^Disk /" | awk '{print $7}')
    
    log_info "Gesamte Sektoren: $total_sectors"
    
    # Berechne End-Sektor basierend auf SIZE
    local size_sectors
    if [[ "$SIZE" =~ G$ ]]; then
        size_sectors=$((${SIZE%G} * 2097152))
    elif [[ "$SIZE" =~ M$ ]]; then
        size_sectors=$((${SIZE%M} * 2048))
    elif [[ "$SIZE" =~ T$ ]]; then
        size_sectors=$((${SIZE%T} * 2097152 * 1024))
    else
        log_error "Ungültiges Größenformat! Nutze M, G oder T (z.B. 100G)"
        exit 1
    fi
    
    log_info "Angeforderte Größe in Sektoren: $size_sectors"
    
    # Verwende fdisk - mit GPT brauchen wir keine Partition Type Auswahl
    {
        echo "n"
        echo ""
        echo ""
        echo "+$SIZE"
        echo "w"
    } | fdisk "$DEVICE" > /dev/null 2>&1
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 1 ]]; then
        log_error "fdisk hat einen Fehler zurückgegeben!"
        exit 1
    fi
    
    log_info "Partition-Befehl an fdisk gesendet"
    sleep 3
    
    # Kernel-Update
    partprobe "$DEVICE" 2>/dev/null || true
    sleep 2
    
    log_info "Partition erstellt: $CREATED_PARTITION"
}

format_partition() {
    local partition="$CREATED_PARTITION"
    
    if [[ -z "$partition" ]]; then
        log_error "Konnte Partition nicht bestimmen!"
        exit 1
    fi
    
    log_step "Formatiere Partition $partition mit $FSTYPE..."
    
    # Warte, bis Partition existiert
    local count=0
    while [[ ! -e "$partition" ]] && [[ $count -lt 10 ]]; do
        log_info "Warte auf Partition $partition... ($((count+1))/10)"
        sleep 2
        count=$((count+1))
    done
    
    if [[ ! -e "$partition" ]]; then
        log_error "Partition $partition existiert nicht!"
        exit 1
    fi
    
    if ! mkfs -t "$FSTYPE" -F "$partition"; then
        log_error "Formatierung fehlgeschlagen!"
        exit 1
    fi
    
    log_info "Formatierung mit $FSTYPE abgeschlossen"
}

create_mountpoint() {
    if [[ ! -d "$MOUNT_POINT" ]]; then
        log_info "Erstelle Mountpoint $MOUNT_POINT..."
        mkdir -p "$MOUNT_POINT"
    fi
}

mount_partition() {
    local partition="$CREATED_PARTITION"
    
    if [[ -z "$partition" ]]; then
        log_error "Konnte Partition nicht bestimmen!"
        exit 1
    fi
    
    log_step "Mounte $partition nach $MOUNT_POINT..."
    
    # Warte, bis Partition existiert und erkannt ist
    local count=0
    while [[ ! -e "$partition" ]] && [[ $count -lt 10 ]]; do
        log_info "Warte auf Partition $partition... ($((count+1))/10)"
        sleep 2
        count=$((count+1))
    done
    
    if [[ ! -e "$partition" ]]; then
        log_error "Partition $partition existiert nicht!"
        exit 1
    fi
    
    log_info "Warte 3 Sekunden vor dem Mounten..."
    sleep 3
    
    if ! mount "$partition" "$MOUNT_POINT"; then
        log_error "Mounten fehlgeschlagen!"
        log_error "Partition: $partition"
        log_error "Mountpoint: $MOUNT_POINT"
        exit 1
    fi
    
    log_info "Erfolgreich gemountet!"
}

add_to_fstab() {
    local partition="$CREATED_PARTITION"
    local uuid
    
    if [[ -z "$partition" ]]; then
        log_error "Konnte Partition nicht bestimmen!"
        return
    fi
    
    uuid=$(blkid -s UUID -o value "$partition" 2>/dev/null)
    
    if [[ -z "$uuid" ]]; then
        log_warn "Konnte UUID nicht ermitteln. Bitte manuell zu /etc/fstab hinzufügen."
        log_info "Device: $partition"
        return
    fi
    
    if ! grep -q "^UUID=$uuid" /etc/fstab; then
        echo "UUID=$uuid $MOUNT_POINT $FSTYPE defaults,nofail 0 2" >> /etc/fstab
        log_info "Eintrag zu /etc/fstab hinzugefügt"
    else
        log_info "Eintrag existiert bereits in /etc/fstab"
    fi
}

show_final_info() {
    echo ""
    log_info "Finale Partition-Informationen:"
    lsblk "$DEVICE"
    echo ""
    log_info "Mount-Status:"
    mount | grep "$MOUNT_POINT" || echo "Nicht gemountet"
    echo ""
    log_info "Speicher-Auslastung:"
    df -h "$MOUNT_POINT" 2>/dev/null || echo "Mountpoint nicht verfügbar"
}

wipe_disk() {
    log_warn "ACHTUNG: Du wirst ALLE Partitionen auf $DEVICE löschen!"
    echo ""
    fdisk -l "$DEVICE" | head -15
    echo ""
    read -p "Wirklich ALLE Partitionen löschen und neu initialisieren? (ja/nein): " confirm
    
    if [[ "$confirm" != "ja" ]]; then
        log_info "Abgebrochen."
        exit 0
    fi
    
    # Unmounte alle Partitionen
    for partition in "$DEVICE"*; do
        if [[ "$partition" != "$DEVICE" ]]; then
            if mount | grep -q "^$partition"; then
                log_info "Unmounte $partition..."
                umount "$partition" 2>/dev/null || umount -l "$partition" 2>/dev/null || true
            fi
        fi
    done
    
    log_info "Warte 2 Sekunden..."
    sleep 2
    
    log_step "Lösche alle Partitionen..."
    parted -s "$DEVICE" mklabel gpt
    
    log_info "Warte 5 Sekunden..."
    sleep 5
    
    partprobe "$DEVICE" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    
    log_info "Disk erfolgreich gelöscht und neu initialisiert!"
    lsblk "$DEVICE"
}

wipe_all() {
    log_warn "ACHTUNG: Dieser Prozess ist SEHR langsam!"
    log_warn "Du wirst die gesamte Disk $DEVICE mit Nullen überschreiben!"
    echo ""
    fdisk -l "$DEVICE" | head -15
    echo ""
    read -p "Wirklich die gesamte Disk überschreiben? (ja/nein): " confirm
    
    if [[ "$confirm" != "ja" ]]; then
        log_info "Abgebrochen."
        exit 0
    fi
    
    read -p "Bist du WIRKLICH sicher? Wiederhole 'JA': " confirm2
    
    if [[ "$confirm2" != "JA" ]]; then
        log_info "Abgebrochen."
        exit 0
    fi
    
    # Unmounte alle Partitionen
    for partition in "$DEVICE"*; do
        if [[ "$partition" != "$DEVICE" ]]; then
            if mount | grep -q "^$partition"; then
                log_info "Unmounte $partition..."
                umount "$partition" 2>/dev/null || umount -l "$partition" 2>/dev/null || true
            fi
        fi
    done
    
    log_info "Warte 2 Sekunden..."
    sleep 2
    
    log_step "Überschreibe Disk mit Nullen (Dies kann mehrere Stunden dauern)..."
    
    if dd if=/dev/zero of="$DEVICE" bs=1M status=progress 2>&1; then
        log_info "Disk erfolgreich überschrieben!"
    else
        log_error "Fehler beim Überschreiben!"
        exit 1
    fi
    
    log_step "Initialisiere GPT..."
    parted -s "$DEVICE" mklabel gpt
    
    log_info "Warte 5 Sekunden..."
    sleep 5
    
    partprobe "$DEVICE" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    
    log_info "Disk erfolgreich gelöscht und überschrieben!"
    lsblk "$DEVICE"
}

# Hauptprogramm
main() {
    # Parse long options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m)
                MOUNT_POINT="$2"
                shift 2
                ;;
            -d)
                DEVICE="$2"
                shift 2
                ;;
            -s)
                SIZE="$2"
                shift 2
                ;;
            -t)
                FSTYPE="$2"
                shift 2
                ;;
            --wipe-disk)
                WIPE_DISK=1
                shift
                ;;
            --wipe-all)
                WIPE_ALL=1
                shift
                ;;
            --format-partition)
                FORMAT_PARTITION=1
                shift
                ;;
            -h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unbekannte Option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    check_root
    
    # Wipe-Disk Mode
    if [[ $WIPE_DISK -eq 1 ]]; then
        if [[ -z "$DEVICE" ]]; then
            log_error "Device (-d) ist erforderlich!"
            exit 1
        fi
        check_device_exists
        wipe_disk
        exit 0
    fi
    
    # Wipe-All Mode
    if [[ $WIPE_ALL -eq 1 ]]; then
        if [[ -z "$DEVICE" ]]; then
            log_error "Device (-d) ist erforderlich!"
            exit 1
        fi
        check_device_exists
        wipe_all
        exit 0
    fi
    
    # Normal Mode: Partition erstellen
    if [[ -z "$MOUNT_POINT" ]] || [[ -z "$DEVICE" ]] || [[ -z "$SIZE" ]]; then
        log_error "Mountpoint (-m), Device (-d) und Größe (-s) sind erforderlich!"
        echo ""
        show_help
        exit 1
    fi
    
    check_device_exists
    validate_size
    
    # Disk-Info anzeigen
    log_step "Disk-Informationen:"
    fdisk -l "$DEVICE" 2>/dev/null | head -20
    echo ""
    
    read -p "Möchtest du fortfahren? (ja/nein): " confirm
    if [[ "$confirm" != "ja" ]]; then
        log_info "Abgebrochen."
        exit 0
    fi
    
    # Logik
    init_gpt_if_needed
    create_partition
    format_partition
    create_mountpoint
    mount_partition
    add_to_fstab
    show_final_info
    
    log_info "Abgeschlossen! Partition ist bereit unter $MOUNT_POINT"
}

main "$@"
