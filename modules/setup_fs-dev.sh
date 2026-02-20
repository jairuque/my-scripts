#!/bin/bash
# Script de configuración completo para desarrollo FacturaScripts en Linux Mint
# Sin Docker, con tema Catppuccin, Nerd Fonts (Inter) y Sublime Text
# Ejecutar con: bash setup-facturascripts-dev-enhanced.sh

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

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si es root
if [ "$EUID" -eq 0 ]; then 
    error "No ejecutes este script como root. Usa tu usuario normal."
    exit 1
fi

# Verificar sudo
if ! sudo -v &>/dev/null; then
    error "Necesitas permisos sudo. Añade tu usuario al grupo sudo."
    exit 1
fi

log "🚀 Iniciando configuración completa de entorno FacturaScripts (Enhanced)..."

# =========================================
# 2. ACTUALIZAR SISTEMA
# =========================================
log "📦 Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# =========================================
# 5. OH-MY-ZSH + POWERLEVEL10K + CATPPUCCIN
# =========================================
log "🎨 Configurando Zsh premium con Catppuccin..."

# Instalar Oh-My-Zsh si no existe
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log "✅ Oh-My-Zsh instalado"
else
    log "✅ Oh-My-Zsh ya existe"
fi

# Powerlevel10k
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    log "✅ Powerlevel10k instalado"
fi

# Tema Catppuccin para Zsh
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin-zsh" ]; then
    git clone https://github.com/JannoTjarks/catppuccin-zsh.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin-zsh
    mkdir -p ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin-flavors
    ln -sf ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin-zsh/catppuccin.zsh-theme ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/
    ln -sf ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin-zsh/catppuccin-flavors/* ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/catppuccin-flavors/
    log "✅ Tema Catppuccin para Zsh instalado"
fi

# Plugins
PLUGINS=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-completions"
)

for plugin in "${PLUGINS[@]}"; do
    PLUGIN_NAME=$(basename $plugin)
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$PLUGIN_NAME" ]; then
        git clone https://github.com/$plugin.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$PLUGIN_NAME
        log "✅ Plugin $PLUGIN_NAME instalado"
    fi
done

# =========================================
# 6. INSTALAR NERD FONTS (INTER)
# =========================================
log "🔤 Instalando Inter Nerd Font..."

FONT_DIR="$HOME/.local/share/fonts/NerdFonts"

if [ ! -d "$FONT_DIR" ]; then
    mkdir -p "$FONT_DIR"
    
    # Descargar Inter Nerd Font v3.2.1
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -O /tmp/JetBrainsMono-nerd-font.zip
    
    # Descomprimir
    unzip -q /tmp/JetBrainsMono-nerd-font.zip -d /tmp/JetBrainsMono-nerd-font
    
    # Mover archivos .ttf al directorio de fonts
    mv /tmp/JetBrainsMono-nerd-font/*.ttf "$FONT_DIR/" 2>/dev/null || true
    
    # Limpiar
    rm -rf /tmp/JetBrainsMono-nerd-font.zip /tmp/JetBrainsMono-nerd-font
    
    # Actualizar caché de fuentes
    fc-cache -f -v
    
    log "✅ Inter Nerd Font instalado en $FONT_DIR"
else
    log "✅ Inter Nerd Font ya instalado"
fi

# =========================================
# 7. CONFIGURAR .ZSHRC CON CATPPUCCIN
# =========================================
log "⚙️ Configurando ~/.zshrc con Catppuccin..."

ZSHRC_CONTENT='
# Tema Catppuccin para Zsh
ZSH_THEME="catppuccin"
CATPPUCCIN_FLAVOR="mocha" # Opciones: mocha, frappe, macchiato, latte
CATPPUCCIN_SHOW_TIME=true

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions composer)

# Configuración Powerlevel10k (compatibilidad)
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="▶ "
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status history time)

# Alias generales
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias gs="git status"
alias gc="git commit -m"
alias gcm="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gco="git checkout"
alias gb="git branch"

# Alias para Sublime Text
alias subl="sublime_text"

# FacturaScripts específicos
alias fs-sync-up="rsync -avz --exclude=.git --exclude=vendor --exclude=node_modules --exclude=cache --exclude=tmp --delete ./ usuario@192.168.1.100:/var/www/html/facturascripts/"
alias fs-sync-down="rsync -avz --exclude=.git --exclude=vendor --exclude=node_modules --exclude=cache --exclude=tmp usuario@192.168.1.100:/var/www/html/facturascripts/ ./"
alias fs-clear-cache="ssh usuario@192.168.1.100 \"sudo rm -rf /var/www/html/facturascripts/cache/*\""
alias fs-logs="ssh usuario@192.168.1.100 \"tail -f /var/log/apache2/error.log\""
alias fs-restart="ssh usuario@192.168.1.100 \"sudo systemctl restart apache2\""
alias fs-permissions="ssh usuario@192.168.1.100 \"sudo chown -R www-data:www-data /var/www/html/facturascripts && sudo chmod -R 755 /var/www/html/facturascripts\""

# Funciones útiles
function fsgrep() {
    grep -r --include="*.php" --include="*.tpl" "$1" .
}

function fs-ssh() {
    ssh usuario@192.168.1.100
}

function fs-cd() {
    cd ~/proyectos/facturascripts
}

function fs-exec() {
    ssh usuario@192.168.1.100 "cd /var/www/html/facturascripts && $*"
}

# Exportar PATH
export PATH=$PATH:~/.composer/vendor/bin:~/bin

# No pedir confirmación al cerrar sesión si hay jobs activos
setopt NO_CHECK_JOBS 2>/dev/null || true
'

# Crear backup y reemplazar .zshrc
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d)
fi

echo "$ZSHRC_CONTENT" > ~/.zshrc

# =========================================
# 8. CONFIGURAR SSH
# =========================================
log "🔐 Configurando SSH..."

mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Configuración SSH
SSH_CONFIG='
Host fs-main
    HostName 192.168.1.100
    User usuario
    Port 22
    IdentityFile ~/.ssh/id_rsa_fs_main
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes

Host fs-mirror
    HostName 192.168.1.101
    User usuario
    Port 22
    IdentityFile ~/.ssh/id_rsa_fs_mirror
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes

Host fs
    HostName 192.168.1.100
    User usuario
'

if [ ! -f ~/.ssh/config ]; then
    echo "$SSH_CONFIG" > ~/.ssh/config
    chmod 600 ~/.ssh/config
    log "✅ Configuración SSH creada"
else
    log "✅ ~/.ssh/config ya existe"
fi

# Generar claves SSH
if [ ! -f ~/.ssh/id_rsa_fs_main ]; then
    log "🔑 Generando clave SSH para servidor principal..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_fs_main -C "facturascripts-main" -N ""
    warn "⚠️  No olvides ejecutar: ssh-copy-id -i ~/.ssh/id_rsa_fs_main.pub usuario@192.168.1.100"
fi

if [ ! -f ~/.ssh/id_rsa_fs_mirror ]; then
    log "🔑 Generando clave SSH para espejo..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_fs_mirror -C "facturascripts-mirror" -N ""
    warn "⚠️  No olvides ejecutar: ssh-copy-id -i ~/.ssh/id_rsa_mirror.pub usuario@192.168.1.101"
fi

# =========================================
# 9. CONFIGURAR GIT GLOBAL
# =========================================
log "📝 Configurando Git global..."

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "code --wait"
git config --global merge.tool "meld"
git config --global mergetool.meld.cmd "meld \$LOCAL \$BASE \$REMOTE \$MERGED"

# =========================================
# 10. HOOKS GIT Y SCRIPTS
# =========================================
log "🪝 Configurando hooks y scripts de Git..."

mkdir -p ~/.git-hooks ~/bin

# Hook post-commit
cat > ~/.git-hooks/post-commit << 'EOF'
#!/bin/bash
LAST_COMMIT=$(git rev-parse HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

git push origin $BRANCH 2>/dev/null

echo "🔄 Sincronizando con espejo 192.168.1.101..."
git push --mirror ssh://usuario@192.168.1.101/home/usuario/mirror/facturascripts.git 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Error al sincronizar con espejo"
    echo "   Para forzar: git push --mirror --force"
    exit 1
fi
EOF

chmod +x ~/.git-hooks/post-commit

# Script de sincronización bidireccional
cat > ~/bin/git-sync-mirror << 'EOF'
#!/bin/bash
REPO_DIR="$1"
if [ -z "$REPO_DIR" ]; then
    REPO_DIR=$(pwd)
fi

cd "$REPO_DIR"
git remote | grep -q "mirror" || git remote add mirror ssh://usuario@192.168.1.101/home/usuario/mirror/facturascripts.git

echo "⬇️  Obteniendo cambios del espejo..."
git fetch mirror

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse mirror/main 2>/dev/null || echo "NO_REMOTE")

if [ "$REMOTE" != "NO_REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
    echo "⚠️  Detectada divergencia"
    read -p "¿Fusionar cambios del espejo? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        git merge mirror/main --no-edit
        echo "✅ Fusionado"
    else
        exit 1
    fi
else
    echo "✅ Sincronizado"
fi
EOF

chmod +x ~/bin/git-sync-mirror

# =========================================
# 11. EXTENSIONES VS CODE (CON CATPPUCCIN)
# =========================================
log "🔌 Instalando extensiones de VS Code..."

EXTENSIONS=(
    felixfbecker.php-debug
    bmewburn.vscode-intelephense-client
    kokororin.vscode-phpfmt
    ecmel.vscode-html-css
    bradlc.vscode-tailwindcss
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    github.copilot
    eamodio.gitlens
    ms-vscode.hexeditor
    oderwat.indent-rainbow
    esbenp.prettier-vscode
    humao.rest-client
    # CATPPUCCIN
    catppuccin.catppuccin-vsc
    catppuccin.catppuccin-vsc-icons
)

for ext in "${EXTENSIONS[@]}"; do
    if ! code --list-extensions | grep -q "^${ext}$"; then
        log "Instalando extensión: $ext"
        code --install-extension $ext
    else
        log "✅ Extensión $ext ya instalada"
    fi
done

# =========================================
# 12. CONFIGURACIÓN VS CODE CON CATPPUCCIN
# =========================================
log "⚙️ Configurando VS Code con Catppuccin..."

mkdir -p ~/.config/Code/User

# settings.json con Catppuccin e Inter Nerd Font
SETTINGS_JSON='{
    "editor.fontSize": 13,
    "editor.fontFamily": "Inter Nerd Font, Fira Code, monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": false,
    "editor.wordWrap": "on",
    "editor.rulers": [80, 120],
    "editor.minimap.enabled": false,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": true
    },
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-latte",
    "files.associations": {
        "*.tpl": "php"
    },
    "files.exclude": {
        "**/.git": true,
        "**/vendor": true,
        "**/cache": true,
        "**/tmp": true
    },
    "search.exclude": {
        "**/vendor": true,
        "**/cache": true,
        "**/tmp": true
    },
    "php.validate.executablePath": "/usr/bin/php",
    "intelephense.files.maxSize": 5000000,
    "intelephense.environment.phpVersion": "8.1.0",
    "[php]": {
        "editor.defaultFormatter": "kokororin.vscode-phpfmt",
        "editor.formatOnSave": true
    },
    "remote.SSH.configFile": "~/.ssh/config",
    "git.autofetch": true,
    "terminal.integrated.defaultProfile.linux": "zsh",
    "terminal.integrated.fontFamily": "Inter Nerd Font",
    "catppuccin.accentColor": "mauve",
    "catppuccin.italicComments": true,
    "catppuccin.italicKeywords": true,
    "catppuccin.boldKeywords": true,
    "catppuccin.workbenchMode": "default"
}'

echo "$SETTINGS_JSON" > ~/.config/Code/User/settings.json

# =========================================
# 13. CONFIGURACIÓN SUBLIME TEXT
# =========================================
log "📝 Configurando Sublime Text..."

# Crear settings de Sublime Text con Catppuccin y Nerd Fonts
SUBLIME_DIR="$HOME/.config/sublime-text/Packages/User"
mkdir -p "$SUBLIME_DIR"

# Preferences.sublime-settings
cat > "$SUBLIME_DIR/Preferences.sublime-settings" << 'EOF'
{
    "font_face": "Inter Nerd Font",
    "font_size": 12,
    "font_options": ["subpixel_antialias", "no_round"],
    "theme": "auto",
    "color_scheme": "Catppuccin Mocha.sublime-color-scheme",
    "ignored_packages": [],
    "translate_tabs_to_spaces": true,
    "tab_size": 4,
    "trim_trailing_white_space_on_save": true,
    "ensure_newline_at_eof_on_save": true,
    "rulers": [80, 120],
    "word_wrap": true,
    "highlight_line": true,
    "caret_style": "smooth"
}
EOF

# Instalar Catppuccin para Sublime Text via Package Control
log "⚠️  Para Catppuccin en Sublime Text, abre el editor y ve a:"
log "    Tools → Install Package Control"
log "    Luego: Preferences → Package Control → Install Package → 'Catppuccin'"

# =========================================
# 14. FIREWALL UFW
# =========================================
log "🔥 Configurando firewall UFW..."

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 22
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo "y" | sudo ufw enable
sudo ufw status verbose

# =========================================
# 15. CREAR ESTRUCTURA DE PROYECTO
# =========================================
log "📁 Creando estructura de proyecto..."

mkdir -p ~/proyectos/facturascripts/.vscode

# launch.json
LAUNCH_JSON='{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug (Remote)",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "log": true,
            "pathMappings": {
                "/var/www/html/facturascripts": "${workspaceFolder}"
            },
            "hostname": "192.168.1.100",
            "xdebugSettings": {
                "max_data": -1,
                "max_children": 128,
                "max_depth": 3
            },
            "ignore": [
                "**/vendor/**",
                "**/cache/**",
                "**/tmp/**"
            ]
        }
    ]
}'

echo "$LAUNCH_JSON" > ~/proyectos/facturascripts/.vscode/launch.json

# tasks.json
TASKS_JSON='{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Sync to Remote",
            "type": "shell",
            "command": "rsync",
            "args": [
                "-avz",
                "--exclude=.git",
                "--exclude=vendor",
                "--exclude=node_modules",
                "--exclude=cache",
                "--exclude=tmp",
                "--delete",
                "${workspaceFolder}/",
                "usuario@192.168.1.100:/var/www/html/facturascripts/"
            ],
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "Sync from Remote",
            "type": "shell",
            "command": "rsync",
            "args": [
                "-avz",
                "--exclude=.git",
                "--exclude=vendor",
                "--exclude=node_modules",
                "--exclude=cache",
                "--exclude=tmp",
                "usuario@192.168.1.100:/var/www/html/facturascripts/",
                "${workspaceFolder}/"
            ],
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "Clear Remote Cache",
            "type": "shell",
            "command": "ssh",
            "args": ["usuario@192.168.1.100", "sudo rm -rf /var/www/html/facturascripts/cache/*"]
        },
        {
            "label": "Watch Remote Logs",
            "type": "shell",
            "command": "ssh",
            "args": ["usuario@192.168.1.100", "tail -f /var/log/apache2/error.log"],
            "isBackground": true,
            "presentation": {
                "reveal": "always",
                "panel": "dedicated"
            }
        },
        {
            "label": "Open in Sublime Text",
            "type": "shell",
            "command": "sublime_text",
            "args": ["${file}"],
            "group": "none"
        }
    ]
}'

echo "$TASKS_JSON" > ~/proyectos/facturascripts/.vscode/tasks.json

# =========================================
# 16. FINALIZACIÓN
# =========================================
log "🎉 ¡Configuración completada!"

echo ""
echo "======================================================"
echo "  PRÓXIMOS PASOS MANUALES (NO AUTOMATIZABLES)"
echo "======================================================"
echo ""
echo "1. COPIAR CLAVES SSH A SERVIDORES:"
echo "   ssh-copy-id -i ~/.ssh/id_rsa_fs_main.pub usuario@192.168.1.100"
echo "   ssh-copy-id -i ~/.ssh/id_rsa_fs_mirror.pub usuario@192.168.1.101"
echo ""
echo "2. CONFIGURAR GIT USER:"
echo "   git config --global user.name \"Tu Nombre\""
echo "   git config --global user.email \"tu@email.com\""
echo ""
echo "3. CAMBIAR SHELL POR DEFECTO A ZSH:"
echo "   chsh -s \$(which zsh)"
echo ""
echo "4. CONFIGURAR CATPPUCCIN EN SUBLIME TEXT:"
echo "   - Abre Sublime Text"
echo "   - Ctrl+Shift+P → 'Install Package Control'"
echo "   - Ctrl+Shift+P → 'Install Package' → Busca 'Catppuccin'"
echo "   - Selecciona: 'Preferences → Color Scheme → Catppuccin → Mocha'"
echo ""
echo "5. INSTALAR TEMA CATPPUCCIN PARA TERMINAL (opcional):"
echo "   - Abre Terminal → Edit → Preferences → Appearance"
echo "   - Selecciona 'Catppuccin Mocha' o importa desde:"
echo "   - https://github.com/catppuccin/gtk"
echo ""
echo "6. INICIAR PROYECTO:"
echo "   cd ~/proyectos/facturascripts"
echo "   git init"
echo "   git config core.hooksPath ~/.git-hooks"
echo "   code ."
echo ""
echo "7. CONFIGURAR DBeaver:"
echo "   - Conexión SSH Tunnel usando fs-main"
echo "   - Base de datos: 192.168.1.100:3306"
echo ""
echo "======================================================"
echo ""
log "⚠️  RECUERDA: Ejecuta 'chsh -s \$(which zsh)' y reinicia sesión"
log "⚠️  El script ha creado backups de archivos modificados"
echo ""
log "📂 Archivos de configuración creados:"
echo "   ~/.zshrc (backup: ~/.zshrc.backup.$(date +%Y%m%d))"
echo "   ~/.ssh/config"
echo "   ~/.git-hooks/post-commit"
echo "   ~/bin/git-sync-mirror"
echo "   ~/.config/Code/User/settings.json"
echo "   ~/.config/sublime-text/Packages/User/Preferences.sublime-settings"
echo "   ~/proyectos/facturascripts/.vscode/{launch,tasks}.json"
echo ""
log "✅ ¡Todo listo! Reinicia tu terminal y ejecuta 'zsh' para empezar."
echo ""
log "💡 TIP: Usa 'subl <archivo>' para abrir archivos rápidamente en Sublime Text"
log "💡 TIP: Usa 'Ctrl+Shift+P → Tasks: Run Task' para sincronizar con el servidor"