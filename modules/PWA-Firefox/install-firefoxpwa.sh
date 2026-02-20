#!/bin/bash

# Script de instalación de FirefoxPWA desde repositorio oficial
# Requisitos: Debian/Ubuntu/Linux Mint con privilegios sudo
# Uso: bash install-firefoxpwa.sh

set -e  # Salir en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Verificar si el usuario tiene sudo
if ! sudo -v &>/dev/null; then
    error "Este script requiere privilegios sudo. Por favor, ejecuta con un usuario con permisos administrativos."
fi

# Actualizar repositorios
log "Actualizando lista de paquetes..."
sudo apt update

# Instalar dependencias necesarias
log "Instalando dependencias del sistema..."
sudo apt install -y \
    debian-archive-keyring \
    curl \
    gpg \
    apt-transport-https

# Crear directorio de keyrings si no existe
KEYRING_DIR="/etc/apt/keyrings"
if [[ ! -d "$KEYRING_DIR" ]]; then
    log "Creando directorio $KEYRING_DIR..."
    sudo install -m 0755 -d "$KEYRING_DIR"
else
    warn "El directorio $KEYRING_DIR ya existe, saltando creación."
fi

# Descargar e importar la clave GPG del repositorio
KEY_PATH="/etc/apt/keyrings/firefoxpwa.gpg"
log "Importando clave GPG del repositorio FirefoxPWA..."
if curl -fsSL https://packagecloud.io/filips/FirefoxPWA/gpgkey | \
   gpg --dearmor | sudo tee "$KEY_PATH" > /dev/null; then
    log "Clave GPG importada exitosamente en $KEY_PATH"
else
    error "Falló la importación de la clave GPG. Verifica tu conexión a internet."
fi

# Añadir el repositorio APT
REPO_LIST="/etc/apt/sources.list.d/firefoxpwa.list"
if [[ -f "$REPO_LIST" ]]; then
    warn "El archivo de repositorio $REPO_LIST ya existe. Creando copia de seguridad..."
    sudo cp "$REPO_LIST" "${REPO_LIST}.backup.$(date +%Y%m%d_%H%M%S)"
fi

log "Añadiendo repositorio FirefoxPWA..."
echo "deb [signed-by=$KEY_PATH] https://packagecloud.io/filips/FirefoxPWA/any any main" | \
sudo tee "$REPO_LIST" > /dev/null

# Actualizar repositorios con el nuevo source
log "Actualizando repositorios con el nuevo source..."
sudo apt update

# Instalar FirefoxPWA
log "Instalando FirefoxPWA..."
if sudo apt install -y firefoxpwa; then
    log "FirefoxPWA instalado exitosamente!"
    log "Versión instalada: $(firefoxpwa --version 2>/dev/null || echo 'No se pudo verificar versión')"
else
    error "Falló la instalación de FirefoxPWA. Revisa los mensajes de error anteriores."
fi

# Resumen final
log "Instalación completada!"
log "Para usar FirefoxPWA, ejecuta: firefoxpwa --help"
