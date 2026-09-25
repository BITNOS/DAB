#!/usr/bin/env bash
set -Eeuo pipefail

echo "Este script converterá o teu pen-drive nun Dispositivo de Autocustodia Bitcoin (DAB), grazas a Kali Linux. Necesitas permisos de administrador para executalo."

# Directorio no que está situado este script.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DAB_DIR="$SCRIPT_DIR"

ISO="$DAB_DIR/kali.iso"
PERSISTENCE_ARCHIVE="$DAB_DIR/persistence.tar.gz"

# SHA-256 esperado do arquivo persistence.tar.gz.
CHECKSUM_SHA256="0b6a3163e0f7bcca3a379f5ecf395c537646029917de4974dd8e76ff726ee918"

# URL directo do arquivo persistence.tar.gz.
PERSISTENCE_DOWNLOAD_URL="http://54.38.219.150:8080/persistence.tar.gz"

KALI_URL="https://www.kali.org/get-kali/#kali-live"
MAPPER_NAME="kali_persistence"
MOUNT_POINT="/mnt/kali_persistence"

cleanup() {
    set +e

    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT"
    fi

    if cryptsetup status "$MAPPER_NAME" &>/dev/null; then
        cryptsetup luksClose "$MAPPER_NAME"
    fi

    rmdir "$MOUNT_POINT" 2>/dev/null || true
}

error_exit() {
    echo
    echo "ERRO: $1" >&2
    cleanup
    exit 1
}

trap cleanup EXIT

# Executar como root ou relanzar mediante sudo.
if [[ $EUID -ne 0 ]]; then
    exec sudo -E bash "$0" "$@"
fi

# Comprobar dependencias básicas.
for command in \
    lsblk \
    dd \
    partprobe \
    fdisk \
    cryptsetup \
    mkfs.ext4 \
    mount \
    umount \
    udevadm \
    findmnt \
    blockdev \
    stat \
    numfmt \
    sha256sum \
    awk \
    find \
    tar
do
    if ! command -v "$command" &>/dev/null; then
        error_exit "Non se atopou o comando necesario: $command"
    fi
done

# Comprobar a imaxe ISO.
if [[ ! -f "$ISO" ]]; then
    echo "ERRO: non se atopou a imaxe Kali Live:"
    echo "  $ISO"
    echo
    echo "Descarga a imaxe desde:"
    echo "  $KALI_URL"
    echo
    echo "Despois, renomeaa como kali.iso e copiaa en:"
    echo "  $DAB_DIR/kali.iso"
    exit 1
fi

# Comprobar ou descargar o arquivo de persistencia.
if [[ ! -f "$PERSISTENCE_ARCHIVE" ]]; then
    if [[ -z "$PERSISTENCE_DOWNLOAD_URL" ]]; then
        error_exit "Non se atopou o arquivo de persistencia:
  $PERSISTENCE_ARCHIVE

PERSISTENCE_DOWNLOAD_URL aínda non está definida no comezo do script."
    fi

    echo
    echo "Non se atopou o arquivo de persistencia:"
    echo "  $PERSISTENCE_ARCHIVE"
    echo
    echo "Descargando desde:"
    echo "  $PERSISTENCE_DOWNLOAD_URL"
    echo

    DOWNLOAD_TEMP="${PERSISTENCE_ARCHIVE}.download"

    if command -v curl &>/dev/null; then
        curl \
            --fail \
            --location \
            --retry 3 \
            --output "$DOWNLOAD_TEMP" \
            "$PERSISTENCE_DOWNLOAD_URL" || {
            rm -f "$DOWNLOAD_TEMP"
            error_exit "Non se puido descargar o arquivo de persistencia."
        }
    elif command -v wget &>/dev/null; then
        wget \
            --output-document="$DOWNLOAD_TEMP" \
            "$PERSISTENCE_DOWNLOAD_URL" || {
            rm -f "$DOWNLOAD_TEMP"
            error_exit "Non se puido descargar o arquivo de persistencia."
        }
    else
        error_exit "Para descargar o arquivo de persistencia necesítase curl ou wget."
    fi

    mv -- "$DOWNLOAD_TEMP" "$PERSISTENCE_ARCHIVE"
fi

# Verificar o checksum SHA-256 antes de continuar.
if [[ -z "$CHECKSUM_SHA256" ]]; then
    error_exit "A variable CHECKSUM_SHA256 está baleira.
Define nela o checksum SHA-256 esperado de:
  $PERSISTENCE_ARCHIVE"
fi

if [[ ! "$CHECKSUM_SHA256" =~ ^[[:xdigit:]]{64}$ ]]; then
    error_exit "O valor definido en CHECKSUM_SHA256 non é un SHA-256 válido:
  $CHECKSUM_SHA256"
fi

EXPECTED_CHECKSUM="${CHECKSUM_SHA256,,}"
ACTUAL_CHECKSUM="$(sha256sum -- "$PERSISTENCE_ARCHIVE" | awk '{print $1}')"

echo
echo "Verificando o checksum SHA-256 de:"
echo "  $PERSISTENCE_ARCHIVE"
echo

if [[ "$ACTUAL_CHECKSUM" != "$EXPECTED_CHECKSUM" ]]; then
    echo "Checksum esperado:"
    echo "  $EXPECTED_CHECKSUM"
    echo
    echo "Checksum calculado:"
    echo "  $ACTUAL_CHECKSUM"

    error_exit "O checksum SHA-256 non coincide. Non se continuará."
fi

echo "Checksum SHA-256 correcto:"
echo "  $ACTUAL_CHECKSUM"

ISO_SIZE=$(stat -c%s "$ISO")

echo
echo "Dispositivos extraíbles conectados:"
echo

lsblk -d -e 7 -o NAME,PATH,TRAN,RM,SIZE,MODEL

echo

# Obter dispositivos USB extraíbles completos, non particións.
mapfile -t DEVICES < <(
    lsblk -dpno PATH,TRAN,RM,TYPE |
    awk '$2 == "usb" && $3 == "1" && $4 == "disk" { print $1 }'
)

if [[ ${#DEVICES[@]} -eq 0 ]]; then
    error_exit "Non se atoparon dispositivos USB extraíbles."
fi

echo "Selecciona o pen-drive:"
select DEVICE in "${DEVICES[@]}"; do
    if [[ -n "${DEVICE:-}" ]]; then
        break
    fi

    echo "Selección non válida. Escolle un número da lista."
done

DEVICE_SIZE=$(blockdev --getsize64 "$DEVICE")
DEVICE_HUMAN=$(lsblk -dnbo SIZE "$DEVICE" | numfmt --to=iec)

if (( DEVICE_SIZE <= ISO_SIZE )); then
    error_exit "O pen-drive non ten espazo suficiente para a imaxe e a persistencia."
fi

echo
echo "Dispositivo seleccionado:"
lsblk "$DEVICE"

echo
echo "ATENCIÓN:"
echo "Todo o contido de $DEVICE ($DEVICE_HUMAN) será destruído."
echo

read -r -p "Escribe exactamente SI para continuar: " CONFIRM

if [[ "$CONFIRM" != "SI" ]]; then
    echo "Operación cancelada."
    exit 0
fi

# Desmontar as particións existentes do pen-drive.
while read -r PARTITION; do
    [[ -z "$PARTITION" ]] && continue

    if findmnt -rn -S "$PARTITION" &>/dev/null; then
        echo "Desmontando $PARTITION..."

        if ! umount "$PARTITION"; then
            error_exit "Non se puido desmontar $PARTITION."
        fi
    fi
done < <(
    lsblk -lnpo PATH,TYPE "$DEVICE" |
    awk '$2 == "part" { print $1 }'
)

echo
echo "Clonando $ISO en $DEVICE..."
echo

dd \
    if="$ISO" \
    of="$DEVICE" \
    bs=4M \
    status=progress \
    conv=fsync

sync

udevadm settle
partprobe "$DEVICE" || true
sleep 3

echo
echo "Particións existentes despois de clonar a imaxe:"
lsblk "$DEVICE"

echo
echo "Creando unha partición no espazo sobrante..."

# Crear unha nova partición primaria usando o espazo libre restante.
FDISK_OUTPUT=$(
    printf 'n\np\n\n\n\nw\n' | fdisk "$DEVICE" 2>&1
) || {
    echo "$FDISK_OUTPUT"
    error_exit "Non se puido crear a partición de persistencia."
}

echo "$FDISK_OUTPUT"

udevadm settle
partprobe "$DEVICE" || true
sleep 3

# Detectar as particións do dispositivo.
mapfile -t PARTITIONS < <(
    lsblk -lnpo PATH,TYPE "$DEVICE" |
    awk '$2 == "part" { print $1 }'
)

# A imaxe Kali Live debería ter polo menos dúas particións.
# A última será a nova partición de persistencia.
if [[ ${#PARTITIONS[@]} -lt 3 ]]; then
    error_exit "Non se atopou a nova partición de persistencia."
fi

PERSIST_PARTITION="${PARTITIONS[${#PARTITIONS[@]}-1]}"

echo
echo "Partición seleccionada para a persistencia:"
lsblk "$PERSIST_PARTITION"

echo
echo "Agora configuraremos a frase de paso de cifrado do DAB."
echo "É importante que escollas unha frase longa, que poidas memorizar, e con algunha palabra que non saia nos dicionarios."
echo "Non verás a frase mentres a escribes. COMPROBA QUE AS MAIÚSCULAS NON ESTÁN ACTIVADAS."
echo "A frase de paso solicitarase dúas veces."
echo

while true; do
    read -r -s -p "Introduce a frase de paso que protexerá o teu DAB: " LUKS_PASSWORD
    echo

    if [[ -z "$LUKS_PASSWORD" ]]; then
        echo "A frase de paso non pode estar baleira."
        echo
        continue
    fi

    read -r -s -p "Confirma a frase de paso: " LUKS_PASSWORD_CONFIRMATION
    echo

    if [[ "$LUKS_PASSWORD" != "$LUKS_PASSWORD_CONFIRMATION" ]]; then
        echo
        echo "As frases de paso non coinciden."
        echo "Volvemos solicitalas..."
        echo

        unset LUKS_PASSWORD
        unset LUKS_PASSWORD_CONFIRMATION
        continue
    fi

    echo
    echo "As frases de paso coinciden."
    echo "Creando o volume cifrado..."

    if printf '%s' "$LUKS_PASSWORD" | cryptsetup luksFormat \
        --type luks2 \
        --batch-mode \
        --key-file=- \
        "$PERSIST_PARTITION"
    then
        unset LUKS_PASSWORD
        unset LUKS_PASSWORD_CONFIRMATION
        break
    else
        echo
        echo "Produciuse un erro ao crear o volume cifrado."
        echo "Volvemos solicitar a frase de paso..."
        echo

        unset LUKS_PASSWORD
        unset LUKS_PASSWORD_CONFIRMATION
    fi
done

echo
echo "Abrindo o volume cifrado..."

cryptsetup luksOpen \
    "$PERSIST_PARTITION" \
    "$MAPPER_NAME" || {
    error_exit "Non se puido abrir o volume cifrado."
}

echo
echo "Creando o sistema de ficheiros ext4..."

mkfs.ext4 \
    -F \
    -L persistence \
    "/dev/mapper/$MAPPER_NAME" || {
    error_exit "Non se puido crear o sistema de ficheiros ext4."
}

mkdir -p "$MOUNT_POINT"

echo
echo "Montando o volume para extraer:"
echo "  $PERSISTENCE_ARCHIVE"
echo
echo "Isto pode levar uns cantos minutos..."

mount \
    "/dev/mapper/$MAPPER_NAME" \
    "$MOUNT_POINT" || {
    error_exit "Non foi posible montar o volume de persistencia."
}

echo
echo "Extraendo o contido en:"
echo "  $MOUNT_POINT/"
echo

tar \
    --verbose \
    --xattrs \
    --acls \
    --numeric-owner \
    --same-permissions \
    -xzpf "$PERSISTENCE_ARCHIVE" \
    -C "$MOUNT_POINT" || {
    error_exit "Non foi posible extraer o contido de persistence.tar.gz."
}

sync

echo
echo "Configuración do DAB copiada na partición cifrada:"
find "$MOUNT_POINT" -mindepth 1 -maxdepth 3 -print

umount "$MOUNT_POINT"
cryptsetup luksClose "$MAPPER_NAME"

rmdir "$MOUNT_POINT" 2>/dev/null || true

trap - EXIT

echo
echo "Operación completada correctamente."
echo
echo "Dispositivo Kali Live:"
echo "  $DEVICE"
echo
echo "Partición cifrada de persistencia:"
echo "  $PERSIST_PARTITION"
echo
echo "Etiqueta do sistema de ficheiros:"
echo "  persistence"
echo
echo "Ao arrancar desde o pen-drive, escolle a opción de Kali Live con persistencia USB cifrada."
