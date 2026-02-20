#!/bin/bash

set -e  # Detener en errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# =========================================
# 4. INSTALAR PAQUETES PRINCIPALES
# =========================================
log "📦 Instalando paquetes principales..."

PACKAGES=(
    # VS Code
    code
    
    # Sublime Text
    sublime-text
    
    # Terminal y shell
    zsh git wget curl sshfs fonts-firacode unzip
    
    # Base de datos
    mysql-workbench
    
    # Utilidades
    flameshot copyq stacer gitg meld ufw
    
    # PHP y herramientas
    php-cli php-curl php-mbstring php-xml php-zip
    
    # Otros
    apt-transport-https ca-certificates software-properties-common
)

for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        log "Instalando $pkg..."
        sudo apt install -y $pkg
    else
        log "✅ $pkg ya instalado"
    fi
done
