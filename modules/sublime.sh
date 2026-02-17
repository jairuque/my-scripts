#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo "ERROR: exit $rc"; exit $rc' ERR INT TERM

# --- Configuración: ajustar según tu repo y Sublime versión ---
REPO_DIR="${HOME}/.config/.my-scripts/sublime"   # <- ruta local a tu repo
# Detectar ruta de Sublime User según plataforma y versión
if [[ "$(uname)" == "Darwin" ]]; then
  USER_DIR="${HOME}/Library/Application Support/Sublime Text/Packages/User"
  INSTALLED_PACKAGES_DIR="${HOME}/Library/Application Support/Sublime Text/Installed Packages"
else
  # Linux: intenta Sublime Text 4, si no existe usa 3
  if [[ -d "${HOME}/.config/sublime-text" ]]; then
    USER_DIR="${HOME}/.config/sublime-text/Packages/User"
    INSTALLED_PACKAGES_DIR="${HOME}/.config/sublime-text/Installed Packages"
  else
    USER_DIR="${HOME}/.config/sublime-text-3/Packages/User"
    INSTALLED_PACKAGES_DIR="${HOME}/.config/sublime-text-3/Installed Packages"
  fi
fi

BACKUP_DIR="${HOME}/.config/sublime-backups/$(date +%Y%m%d%H%M%S)"
DRY_RUN=0
VERBOSE=0

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--repo PATH] [--verbose]
  --dry-run    Simula acciones sin modificar archivos
  --repo PATH  Ruta al repo que contiene sublime/User
  --verbose    Muestra pasos detallados
EOF
  exit 0
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --repo) REPO_DIR="$2"; shift 2 ;;
    --verbose) VERBOSE=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

log() { [[ $VERBOSE -eq 1 ]] && echo "[INFO] $*"; }
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] $*"
  else
    log "RUN: $*"
    eval "$@"
  fi
}

# Validaciones
if [[ ! -d "$REPO_DIR" ]]; then
  echo "ERROR: repo no encontrado en $REPO_DIR"
  exit 1
fi
if [[ ! -d "$REPO_DIR/User" ]]; then
  echo "ERROR: no existe $REPO_DIR/User con la configuración de Sublime"
  exit 1
fi

echo "User dir detectado: $USER_DIR"
echo "Repo dir: $REPO_DIR"

# Crear backup si existe User actual y no es symlink
if [[ -e "$USER_DIR" && ! -L "$USER_DIR" ]]; then
  run "mkdir -p '$BACKUP_DIR'"
  run "mv '$USER_DIR' '${BACKUP_DIR}/User'"
  echo "Backup creado en ${BACKUP_DIR}"
fi

# Asegurar directorios
run "mkdir -p '$(dirname "$USER_DIR")'"
run "mkdir -p '$INSTALLED_PACKAGES_DIR'"

# Copiar archivos desde repo al User
run "cp -a '$REPO_DIR/User/.' '$USER_DIR/'"
echo "Archivos copiados a $USER_DIR"

# Instalar Package Control si falta
PC_PKG="${INSTALLED_PACKAGES_DIR}/Package Control.sublime-package"
if [[ ! -f "$PC_PKG" ]]; then
  echo "Package Control no encontrado. Instalando..."
  run "curl -fsSL 'https://packagecontrol.io/Package%20Control.sublime-package' -o '$PC_PKG'"
  echo "Package Control instalado."
else
  log "Package Control ya instalado."
fi

echo "Hecho. Abre Sublime Text y espera a que Package Control instale los paquetes listados en Package Control.sublime-settings."
