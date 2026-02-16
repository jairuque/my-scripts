#!/usr/bin/env bash
#===============================================================================
#  setup-terminal.sh — Modern Terminal Bootstrap
#  Zsh + Oh My Zsh + Starship (catppuccin-powerline) + Nerd Fonts + Terminal Theming
#
#  License: MIT
#  Compat : Ubuntu/Debian, Fedora/RHEL, Arch, openSUSE
#===============================================================================
set -Eeuo pipefail

#---------------------------------------
# Constants
#---------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.1.0"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly NERD_FONTS_REPO="https://github.com/ryanoasis/nerd-fonts.git"
readonly STARSHIP_INSTALL_URL="https://starship.rs/install.sh"
readonly OHMYZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
readonly OHMYZSH_PLUGINS_BASE="https://github.com/zsh-users"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(eval echo "~${TARGET_USER}")"

#---------------------------------------
# Catppuccin Mocha theme sources
#---------------------------------------
readonly CATPPUCCIN_BASE="https://raw.githubusercontent.com/catppuccin"
readonly CATPPUCCIN_ALACRITTY="${CATPPUCCIN_BASE}/alacritty/main/catppuccin-mocha.toml"
readonly CATPPUCCIN_ALACRITTY_YAML="${CATPPUCCIN_BASE}/alacritty/v0.2.0/catppuccin-mocha.yml"
readonly CATPPUCCIN_KITTY="${CATPPUCCIN_BASE}/kitty/main/themes/mocha.conf"
readonly CATPPUCCIN_KONSOLE="${CATPPUCCIN_BASE}/konsole/main/catppuccin-mocha.colorscheme"
readonly CATPPUCCIN_FOOT="${CATPPUCCIN_BASE}/foot/main/themes/catppuccin-mocha.ini"
readonly CATPPUCCIN_TERMINATOR="${CATPPUCCIN_BASE}/terminator/main/catppuccin-mocha.config"

# Catppuccin Mocha palette (for dconf-based terminals)
readonly CM_BG="'#1E1E2E'"
readonly CM_FG="'#CDD6F4'"
readonly CM_CURSOR="'#F5E0DC'"
readonly CM_BLACK="'#45475A'"
readonly CM_RED="'#F38BA8'"
readonly CM_GREEN="'#A6E3A1'"
readonly CM_YELLOW="'#F9E2AF'"
readonly CM_BLUE="'#89B4FA'"
readonly CM_MAGENTA="'#F5C2E7'"
readonly CM_CYAN="'#94E2D5'"
readonly CM_WHITE="'#BAC2DE'"
readonly CM_BRBLACK="'#585B70'"
readonly CM_BRRED="'#F38BA8'"
readonly CM_BRGREEN="'#A6E3A1'"
readonly CM_BRYELLOW="'#F9E2AF'"
readonly CM_BRBLUE="'#89B4FA'"
readonly CM_BRMAGENTA="'#F5C2E7'"
readonly CM_BRCYAN="'#94E2D5'"
readonly CM_BRWHITE="'#A6ADC8'"

#---------------------------------------
# Default flags
#---------------------------------------
NON_INTERACTIVE=false
INSTALL_FONTS=true
SKIP_FONTS=false
FONT_NAME=""
SET_DEFAULT_SHELL=true
DRY_RUN=false
VERBOSE=false

PKG_MANAGER=""
PKG_INSTALL_CMD=""

#---------------------------------------
# Colors (fallback for non-TTY)
#---------------------------------------
if [[ -t 1 ]]; then
    C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'; C_CYAN='\033[0;36m'; C_BOLD='\033[1m'; C_RESET='\033[0m'
else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_BOLD=''; C_RESET=''
fi

#---------------------------------------
# Logging
#---------------------------------------
log_info()  { echo -e "${C_GREEN}[INFO]${C_RESET}  $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*" >&2; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }
log_step()  { echo -e "${C_CYAN}[STEP]${C_RESET}  ${C_BOLD}$*${C_RESET}"; }
log_debug() { $VERBOSE && echo -e "${C_BLUE}[DEBUG]${C_RESET} $*" || true; }
log_dry()   { echo -e "${C_YELLOW}[DRY-RUN]${C_RESET} $*"; }

#---------------------------------------
# Trap
#---------------------------------------
_on_error() {
    local exit_code=$?
    log_error "Script failed at line $1 with exit code ${exit_code}."
    cleanup
    exit "${exit_code}"
}
trap '_on_error $LINENO' ERR

#---------------------------------------
# Execution helpers
#---------------------------------------
run() {
    if $DRY_RUN; then log_dry "$*"; else log_debug "exec: $*"; eval "$@"; fi
}

run_as_user() {
    if $DRY_RUN; then
        log_dry "(as ${TARGET_USER}) $*"
    else
        log_debug "exec (as ${TARGET_USER}): $*"
        sudo -u "${TARGET_USER}" bash -c "$*"
    fi
}

#===============================================================================
# CLI
#===============================================================================

show_help() {
    cat <<EOF
${C_BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${C_RESET} — Modern Terminal Bootstrap

${C_BOLD}USAGE:${C_RESET}
    sudo bash ${SCRIPT_NAME} [OPTIONS]

${C_BOLD}OPTIONS:${C_RESET}
    --non-interactive       Skip interactive prompts (use defaults)
    --font <name>           Install specific Nerd Font (e.g., JetBrainsMono)
    --install-fonts         Force font installation (default)
    --skip-fonts            Skip Nerd Font installation
    --set-default-shell     Set Zsh as default shell (default)
    --no-set-default-shell  Do NOT change default shell
    --dry-run               Simulate without executing
    --verbose               Debug output
    -h, --help              This help
    -v, --version           Version
EOF
    exit 0
}

show_version() { echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"; exit 0; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --non-interactive)      NON_INTERACTIVE=true ;;
            --font)
                shift
                [[ -z "${1:-}" ]] && { log_error "--font requires a name"; exit 1; }
                FONT_NAME="$1"; INSTALL_FONTS=true; SKIP_FONTS=false
                ;;
            --install-fonts)        INSTALL_FONTS=true; SKIP_FONTS=false ;;
            --skip-fonts)           SKIP_FONTS=true; INSTALL_FONTS=false ;;
            --set-default-shell)    SET_DEFAULT_SHELL=true ;;
            --no-set-default-shell) SET_DEFAULT_SHELL=false ;;
            --dry-run)              DRY_RUN=true ;;
            --verbose)              VERBOSE=true ;;
            -h|--help)              show_help ;;
            -v|--version)           show_version ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
}

#===============================================================================
# PACKAGE MANAGEMENT
#===============================================================================

detect_pkg_manager() {
    log_step "Detecting package manager..."
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"; PKG_INSTALL_CMD="apt-get install -y"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"; PKG_INSTALL_CMD="dnf install -y"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"; PKG_INSTALL_CMD="yum install -y"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"; PKG_INSTALL_CMD="pacman -S --noconfirm --needed"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"; PKG_INSTALL_CMD="zypper install -y"
    else
        log_error "No supported package manager (apt, dnf, yum, pacman, zypper)."
        exit 1
    fi
    log_info "Detected: ${C_BOLD}${PKG_MANAGER}${C_RESET}"
}

check_prereqs() {
    log_step "Checking prerequisites..."
    [[ $EUID -ne 0 ]] && { log_error "Run with sudo or as root."; exit 1; }

    case "${PKG_MANAGER}" in
        apt)    run "apt-get update -qq" ;;
        pacman) run "pacman -Sy --noconfirm" ;;
        zypper) run "zypper refresh -q" ;;
        *)      : ;;
    esac

    local deps=(git curl wget unzip fontconfig)
    log_info "Installing base dependencies: ${deps[*]}"
    run "${PKG_INSTALL_CMD} ${deps[*]}"
}

install_packages() {
    local packages=("$@")
    [[ ${#packages[@]} -eq 0 ]] && return 0
    run "${PKG_INSTALL_CMD} ${packages[*]}"
}

#===============================================================================
# ZSH
#===============================================================================

install_zsh() {
    log_step "Installing Zsh..."
    if command -v zsh &>/dev/null; then
        log_info "Zsh already installed: $(zsh --version)"
        return 0
    fi
    install_packages zsh
    log_info "Zsh installed: $(zsh --version)"
}

#===============================================================================
# OH MY ZSH
#===============================================================================

install_ohmyzsh() {
    log_step "Installing Oh My Zsh..."
    local omz_dir="${TARGET_HOME}/.oh-my-zsh"
    if [[ -d "${omz_dir}" ]]; then
        log_info "Oh My Zsh already installed."
        return 0
    fi
    if $DRY_RUN; then log_dry "Would install Oh My Zsh"; return 0; fi
    run_as_user "curl -fsSL '${OHMYZSH_INSTALL_URL}' | RUNZSH=no CHSH=no sh"
    log_info "Oh My Zsh installed."
}

install_ohmyzsh_plugins() {
    log_step "Installing Oh My Zsh plugins..."
    local custom_dir="${TARGET_HOME}/.oh-my-zsh/custom/plugins"

    declare -A plugins=(
        [zsh-autosuggestions]="${OHMYZSH_PLUGINS_BASE}/zsh-autosuggestions.git"
        [zsh-syntax-highlighting]="${OHMYZSH_PLUGINS_BASE}/zsh-syntax-highlighting.git"
        [zsh-completions]="${OHMYZSH_PLUGINS_BASE}/zsh-completions.git"
    )

    for plugin in "${!plugins[@]}"; do
        local dest="${custom_dir}/${plugin}"
        if [[ -d "${dest}" ]]; then
            log_info "Plugin '${plugin}' already exists. Skipping."
            continue
        fi
        log_info "Cloning: ${plugin}"
        run_as_user "git clone --depth 1 '${plugins[$plugin]}' '${dest}'"
    done
    log_info "All plugins ready."
}

#===============================================================================
# STARSHIP
#===============================================================================

install_starship() {
    log_step "Installing Starship..."
    if command -v starship &>/dev/null; then
        log_info "Starship already installed: $(starship --version | head -1)"
        return 0
    fi
    if $DRY_RUN; then log_dry "Would install Starship"; return 0; fi
    curl -fsSL "${STARSHIP_INSTALL_URL}" | sh -s -- --yes
    log_info "Starship installed: $(starship --version | head -1)"
}

configure_starship() {
    log_step "Configuring Starship (catppuccin-powerline)..."
    local config_dir="${TARGET_HOME}/.config"
    local config_file="${config_dir}/starship.toml"

    run_as_user "mkdir -p '${config_dir}'"

    if [[ -f "${config_file}" ]]; then
        local backup="${config_file}.bak.${TIMESTAMP}"
        log_info "Backup: ${backup}"
        run "cp '${config_file}' '${backup}'"
        run "chown ${TARGET_USER}:${TARGET_USER} '${backup}'"
    fi

    if $DRY_RUN; then log_dry "Would apply catppuccin-powerline preset"; return 0; fi
    run_as_user "starship preset catppuccin-powerline -o '${config_file}'"
    log_info "Preset applied -> ${config_file}"
}

#===============================================================================
# NERD FONTS
#===============================================================================

_nerd_font_family() {
    local font="$1"
    declare -A font_family_map=(
        [FiraCode]="FiraCode Nerd Font"
        [JetBrainsMono]="JetBrainsMono Nerd Font"
        [Hack]="Hack Nerd Font"
        [Meslo]="MesloLGS Nerd Font"
        [SourceCodePro]="SauceCodePro Nerd Font"
        [UbuntuMono]="UbuntuMono Nerd Font"
        [CascadiaCode]="CaskaydiaCove Nerd Font"
        [Inconsolata]="Inconsolata Nerd Font"
        [RobotoMono]="RobotoMono Nerd Font"
        [DroidSansMono]="DroidSansM Nerd Font"
    )
    echo "${font_family_map[$font]:-${font} Nerd Font}"
}

_select_font() {
    local popular_fonts=(
        "FiraCode"
        "JetBrainsMono"
        "Hack"
        "Meslo"
        "SourceCodePro"
        "UbuntuMono"
        "CascadiaCode"
        "Inconsolata"
        "RobotoMono"
        "DroidSansMono"
    )

    echo ""
    echo -e "${C_BOLD}Select a Nerd Font:${C_RESET}"
    echo ""
    local i=1
    for f in "${popular_fonts[@]}"; do
        printf "  ${C_CYAN}%2d${C_RESET}) %s\n" "$i" "$f"
        i=$((i + 1))
    done
    printf "  ${C_CYAN}%2d${C_RESET}) Custom (type name)\n" "$i"
    echo ""

    local choice
    read -rp "Enter number [default: 2 - JetBrainsMono]: " choice
    choice="${choice:-2}"

    if [[ "${choice}" =~ ^[0-9]+$ ]]; then
        if (( choice >= 1 && choice <= ${#popular_fonts[@]} )); then
            FONT_NAME="${popular_fonts[$((choice - 1))]}"
        elif (( choice == ${#popular_fonts[@]} + 1 )); then
            read -rp "Enter exact Nerd Font name: " FONT_NAME
        else
            log_warn "Invalid selection. Defaulting to JetBrainsMono."
            FONT_NAME="JetBrainsMono"
        fi
    else
        log_warn "Invalid input. Defaulting to JetBrainsMono."
        FONT_NAME="JetBrainsMono"
    fi
    log_info "Selected: ${FONT_NAME}"
}

install_nerd_font() {
    if $SKIP_FONTS; then
        log_info "Skipping fonts (--skip-fonts)."
        return 0
    fi
    log_step "Installing Nerd Font..."

    local font="${FONT_NAME}"
    if [[ -z "${font}" ]]; then
        if $NON_INTERACTIVE; then
            font="JetBrainsMono"
            log_info "Default: ${font}"
        else
            _select_font
            font="${FONT_NAME}"
        fi
    fi
    [[ -z "${font}" ]] && { log_error "No font selected."; return 1; }

    FONT_NAME="${font}"

    local fonts_dir="/usr/share/fonts/nerd-fonts-${font,,}"

    if [[ -d "${fonts_dir}" ]] && ls "${fonts_dir}"/*.ttf &>/dev/null 2>&1; then
        log_info "Font '${font}' already installed. Skipping."
        return 0
    fi

    if $DRY_RUN; then log_dry "Would install '${font}' to ${fonts_dir}"; return 0; fi

    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/nerd-font-XXXXXX)"
    log_info "Cloning nerd-fonts (sparse) for '${font}'..."

    git clone --filter=blob:none --sparse --depth 1 \
        "${NERD_FONTS_REPO}" "${tmp_dir}/nerd-fonts"

    cd "${tmp_dir}/nerd-fonts"
    git sparse-checkout add "patched-fonts/${font}"

    local font_files
    font_files="$(find "patched-fonts/${font}" \( -name '*.ttf' -o -name '*.otf' \) 2>/dev/null)"

    if [[ -z "${font_files}" ]]; then
        log_error "No font files found for '${font}'. Verify name matches nerd-fonts repo."
        cd /
        rm -rf "${tmp_dir}"
        return 1
    fi

    mkdir -p "${fonts_dir}"
    echo "${font_files}" | while IFS= read -r f; do
        cp "${f}" "${fonts_dir}/"
    done

    fc-cache -fv "${fonts_dir}" >/dev/null 2>&1
    log_info "Font '${font}' installed -> ${fonts_dir}"

    cd /
    rm -rf "${tmp_dir}"
}

#===============================================================================
# CATPPUCCIN MOCHA — TERMINAL THEMING
#===============================================================================

_download_theme() {
    local url="$1" dest="$2"
    if [[ -f "${dest}" ]]; then
        log_info "Theme already exists: ${dest}"
        return 0
    fi
    local dest_dir
    dest_dir="$(dirname "${dest}")"
    run_as_user "mkdir -p '${dest_dir}'"
    if $DRY_RUN; then
        log_dry "Would download ${url} -> ${dest}"
    else
        log_debug "Downloading: ${url}"
        run_as_user "curl -fsSL '${url}' -o '${dest}'"
        log_info "Downloaded -> ${dest}"
    fi
}

# --- XFCE helper ---
_xfce_set_key() {
    local file="$1" key="$2" value="$3"
    if grep -qE "^${key}=" "${file}" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "${file}"
    else
        sed -i "/^\[Configuration\]/a ${key}=${value}" "${file}"
    fi
}

# --- Alacritty theme ---
_theme_alacritty() {
    local config_dir="${TARGET_HOME}/.config/alacritty"
    local config_toml="${config_dir}/alacritty.toml"
    local config_yml="${config_dir}/alacritty.yml"
    local themes_dir="${config_dir}/themes"

    if [[ -f "${config_toml}" ]]; then
        _download_theme "${CATPPUCCIN_ALACRITTY}" "${themes_dir}/catppuccin-mocha.toml"
        if ! grep -qF 'catppuccin-mocha.toml' "${config_toml}" 2>/dev/null; then
            if $DRY_RUN; then
                log_dry "Would add import to alacritty.toml"
            else
                local tmp; tmp="$(mktemp)"
                echo 'import = ["~/.config/alacritty/themes/catppuccin-mocha.toml"]' > "${tmp}"
                echo "" >> "${tmp}"
                cat "${config_toml}" >> "${tmp}"
                run_as_user "cp '${tmp}' '${config_toml}'"
                rm -f "${tmp}"
                log_info "Added Catppuccin import to alacritty.toml"
            fi
        else
            log_info "Alacritty TOML already imports Catppuccin."
        fi
    elif [[ -f "${config_yml}" ]]; then
        _download_theme "${CATPPUCCIN_ALACRITTY_YAML}" "${themes_dir}/catppuccin-mocha.yml"
        if ! grep -qF 'catppuccin-mocha.yml' "${config_yml}" 2>/dev/null; then
            if $DRY_RUN; then
                log_dry "Would add import to alacritty.yml"
            else
                run_as_user "echo '' >> '${config_yml}'"
                run_as_user "echo 'import:' >> '${config_yml}'"
                run_as_user "echo '  - ~/.config/alacritty/themes/catppuccin-mocha.yml' >> '${config_yml}'"
                log_info "Added Catppuccin import to alacritty.yml"
            fi
        else
            log_info "Alacritty YAML already imports Catppuccin."
        fi
    else
        run_as_user "mkdir -p '${config_dir}'"
        _download_theme "${CATPPUCCIN_ALACRITTY}" "${themes_dir}/catppuccin-mocha.toml"
        if $DRY_RUN; then
            log_dry "Would create alacritty.toml with Catppuccin import"
        else
            run_as_user "echo 'import = [\"~/.config/alacritty/themes/catppuccin-mocha.toml\"]' > '${config_toml}'"
            log_info "Created alacritty.toml with Catppuccin Mocha."
        fi
    fi
}

# --- Kitty theme ---
_theme_kitty() {
    local config_dir="${TARGET_HOME}/.config/kitty"
    local config_file="${config_dir}/kitty.conf"
    local theme_file="${config_dir}/themes/catppuccin-mocha.conf"

    _download_theme "${CATPPUCCIN_KITTY}" "${theme_file}"

    run_as_user "mkdir -p '${config_dir}'"
    [[ -f "${config_file}" ]] || run_as_user "touch '${config_file}'"

    local include_line="include themes/catppuccin-mocha.conf"

    if ! grep -qF 'catppuccin-mocha.conf' "${config_file}" 2>/dev/null; then
        if $DRY_RUN; then
            log_dry "Would add include to kitty.conf"
        else
            if grep -qE '^\s*include\s+.*theme' "${config_file}" 2>/dev/null; then
                sed -i 's|^\(\s*include\s.*theme\)|# \1|' "${config_file}"
                log_info "Commented out previous theme include in kitty.conf"
            fi
            run_as_user "echo '' >> '${config_file}'"
            run_as_user "echo '# Catppuccin Mocha' >> '${config_file}'"
            run_as_user "echo '${include_line}' >> '${config_file}'"
            log_info "Added Catppuccin include to kitty.conf"
        fi
    else
        log_info "Kitty already includes Catppuccin."
    fi
}

# --- GNOME Terminal theme ---
_theme_gnome_terminal() {
    if ! command -v dconf &>/dev/null; then
        log_warn "dconf not found. Installing..."
        install_packages dconf-cli
    fi

    if $DRY_RUN; then
        log_dry "Would create GNOME Terminal Catppuccin Mocha profile via dconf"
        return 0
    fi

    local profile_id="catppuccin-mocha-$(echo -n 'catppuccin-mocha' | md5sum | cut -c1-8)"
    local dconf_path="/org/gnome/terminal/legacy/profiles:/:${profile_id}"

    local existing_list
    existing_list="$(run_as_user "dconf read /org/gnome/terminal/legacy/profiles:/list" 2>/dev/null || echo "[]")"

    if echo "${existing_list}" | grep -qF "${profile_id}"; then
        log_info "GNOME Terminal Catppuccin profile already exists."
        return 0
    fi

    if [[ "${existing_list}" == "[]" ]] || [[ -z "${existing_list}" ]]; then
        run_as_user "dconf write /org/gnome/terminal/legacy/profiles:/list \"['${profile_id}']\""
    else
        local new_list
        new_list="$(echo "${existing_list}" | sed "s|]|, '${profile_id}']|")"
        run_as_user "dconf write /org/gnome/terminal/legacy/profiles:/list \"${new_list}\""
    fi

    run_as_user "dconf write ${dconf_path}/visible-name \"'Catppuccin Mocha'\""
    run_as_user "dconf write ${dconf_path}/background-color \"${CM_BG}\""
    run_as_user "dconf write ${dconf_path}/foreground-color \"${CM_FG}\""
    run_as_user "dconf write ${dconf_path}/cursor-background-color \"${CM_CURSOR}\""
    run_as_user "dconf write ${dconf_path}/cursor-foreground-color \"${CM_BG}\""
    run_as_user "dconf write ${dconf_path}/cursor-colors-set true"
    run_as_user "dconf write ${dconf_path}/use-theme-colors false"
    run_as_user "dconf write ${dconf_path}/bold-is-bright true"

    local palette="[${CM_BLACK}, ${CM_RED}, ${CM_GREEN}, ${CM_YELLOW}, ${CM_BLUE}, ${CM_MAGENTA}, ${CM_CYAN}, ${CM_WHITE}, ${CM_BRBLACK}, ${CM_BRRED}, ${CM_BRGREEN}, ${CM_BRYELLOW}, ${CM_BRBLUE}, ${CM_BRMAGENTA}, ${CM_BRCYAN}, ${CM_BRWHITE}]"
    run_as_user "dconf write ${dconf_path}/palette \"${palette}\""

    run_as_user "dconf write /org/gnome/terminal/legacy/profiles:/default \"'${profile_id}'\""

    log_info "GNOME Terminal: Catppuccin Mocha profile created and set as default."
}

# --- XFCE Terminal theme ---
_theme_xfce_terminal() {
    local config_dir="${TARGET_HOME}/.config/xfce4/terminal"
    local config_file="${config_dir}/terminalrc"

    run_as_user "mkdir -p '${config_dir}'"

    if $DRY_RUN; then
        log_dry "Would apply Catppuccin Mocha to XFCE Terminal terminalrc"
        return 0
    fi

    if [[ -f "${config_file}" ]]; then
        run "cp '${config_file}' '${config_file}.bak.${TIMESTAMP}'"
        run "chown ${TARGET_USER}:${TARGET_USER} '${config_file}.bak.${TIMESTAMP}'"
    fi

    local xfce_bg="#1E1E2E" xfce_fg="#CDD6F4" xfce_cursor="#F5E0DC"
    local xfce_palette="#45475A;#F38BA8;#A6E3A1;#F9E2AF;#89B4FA;#F5C2E7;#94E2D5;#BAC2DE;#585B70;#F38BA8;#A6E3A1;#F9E2AF;#89B4FA;#F5C2E7;#94E2D5;#A6ADC8"

    if [[ -f "${config_file}" ]] && grep -q '\[Configuration\]' "${config_file}"; then
        _xfce_set_key "${config_file}" "ColorBackground" "${xfce_bg}"
        _xfce_set_key "${config_file}" "ColorForeground" "${xfce_fg}"
        _xfce_set_key "${config_file}" "ColorCursor" "${xfce_cursor}"
        _xfce_set_key "${config_file}" "ColorPalette" "${xfce_palette}"
        _xfce_set_key "${config_file}" "ColorUseTheme" "FALSE"
    else
        run_as_user "cat > '${config_file}' << 'XFCE_EOF'
[Configuration]
ColorBackground=${xfce_bg}
ColorForeground=${xfce_fg}
ColorCursor=${xfce_cursor}
ColorPalette=${xfce_palette}
ColorUseTheme=FALSE
XFCE_EOF"
    fi

    log_info "XFCE Terminal: Catppuccin Mocha applied."
}

# --- Konsole theme ---
_theme_konsole() {
    local schemes_dir="${TARGET_HOME}/.local/share/konsole"
    local scheme_file="${schemes_dir}/catppuccin-mocha.colorscheme"

    _download_theme "${CATPPUCCIN_KONSOLE}" "${scheme_file}"

    if $DRY_RUN; then
        log_dry "Would set Konsole default colorscheme to Catppuccin Mocha"
        return 0
    fi

    local profile_dir="${TARGET_HOME}/.local/share/konsole"
    local default_profile
    default_profile="$(find "${profile_dir}" -maxdepth 1 -name '*.profile' 2>/dev/null | head -1)"

    if [[ -n "${default_profile}" ]]; then
        if grep -qE '^\s*ColorScheme=' "${default_profile}" 2>/dev/null; then
            sed -i 's|^[[:space:]]*ColorScheme=.*|ColorScheme=catppuccin-mocha|' "${default_profile}"
        else
            echo "ColorScheme=catppuccin-mocha" >> "${default_profile}"
        fi
        log_info "Konsole: ColorScheme set in $(basename "${default_profile}")"
    else
        log_warn "Konsole: No .profile found. Theme installed but select manually."
        echo -e "  ${C_CYAN}-> Settings > Edit Profile > Appearance > catppuccin-mocha${C_RESET}"
    fi
}

# --- Foot theme ---
_theme_foot() {
    local config_dir="${TARGET_HOME}/.config/foot"
    local config_file="${config_dir}/foot.ini"
    local theme_file="${config_dir}/themes/catppuccin-mocha.ini"

    _download_theme "${CATPPUCCIN_FOOT}" "${theme_file}"

    run_as_user "mkdir -p '${config_dir}'"
    [[ -f "${config_file}" ]] || run_as_user "touch '${config_file}'"

    local include_line="include=themes/catppuccin-mocha.ini"

    if ! grep -qF 'catppuccin-mocha.ini' "${config_file}" 2>/dev/null; then
        if $DRY_RUN; then
            log_dry "Would add include to foot.ini"
        else
            if grep -qE '^\s*include=.*theme' "${config_file}" 2>/dev/null; then
                sed -i 's|^\(\s*include=.*theme\)|# \1|' "${config_file}"
            fi
            local tmp; tmp="$(mktemp)"
            echo "# Catppuccin Mocha" > "${tmp}"
            echo "${include_line}" >> "${tmp}"
            echo "" >> "${tmp}"
            cat "${config_file}" >> "${tmp}"
            run_as_user "cp '${tmp}' '${config_file}'"
            rm -f "${tmp}"
            log_info "Added Catppuccin include to foot.ini"
        fi
    else
        log_info "Foot already includes Catppuccin."
    fi
}

# --- WezTerm theme ---
_theme_wezterm() {
    local config_dir="${TARGET_HOME}/.config/wezterm"
    local config_file="${config_dir}/wezterm.lua"

    run_as_user "mkdir -p '${config_dir}'"

    if $DRY_RUN; then
        log_dry "Would configure WezTerm with Catppuccin Mocha"
        return 0
    fi

    local color_line='config.color_scheme = "Catppuccin Mocha"'

    if [[ -f "${config_file}" ]]; then
        if grep -qF 'Catppuccin Mocha' "${config_file}" 2>/dev/null; then
            log_info "WezTerm already has Catppuccin Mocha."
            return 0
        fi
        if grep -qE '^\s*config\.color_scheme' "${config_file}" 2>/dev/null; then
            sed -i "s|^[[:space:]]*config\.color_scheme.*|${color_line}|" "${config_file}"
            log_info "WezTerm: Updated color_scheme to Catppuccin Mocha."
        else
            sed -i "/^return config/i ${color_line}" "${config_file}"
            log_info "WezTerm: Added Catppuccin Mocha color_scheme."
        fi
    else
        run_as_user "cat > '${config_file}' << 'WEZ_EOF'
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = \"Catppuccin Mocha\"

return config
WEZ_EOF"
        log_info "WezTerm: Created config with Catppuccin Mocha."
    fi
}

# --- Terminator theme ---
_theme_terminator() {
    local config_dir="${TARGET_HOME}/.config/terminator"
    local config_file="${config_dir}/config"

    run_as_user "mkdir -p '${config_dir}'"

    if $DRY_RUN; then
        log_dry "Would apply Catppuccin Mocha to Terminator config"
        return 0
    fi

    if [[ -f "${config_file}" ]] && grep -qF 'catppuccin-mocha' "${config_file}" 2>/dev/null; then
        log_info "Terminator already has Catppuccin Mocha."
        return 0
    fi

    [[ -f "${config_file}" ]] && run "cp '${config_file}' '${config_file}.bak.${TIMESTAMP}'"

    local tmp_theme; tmp_theme="$(mktemp)"
    curl -fsSL "${CATPPUCCIN_TERMINATOR}" -o "${tmp_theme}" 2>/dev/null

    if [[ -f "${config_file}" ]] && grep -q '\[profiles\]' "${config_file}"; then
        sed -i '/^\[profiles\]/r '"${tmp_theme}" "${config_file}"
    else
        {
            echo "[profiles]"
            cat "${tmp_theme}"
        } > "${config_file}"
        run "chown ${TARGET_USER}:${TARGET_USER} '${config_file}'"
    fi

    rm -f "${tmp_theme}"
    log_info "Terminator: Catppuccin Mocha profile added."
    echo -e "  ${C_CYAN}-> Right-click > Profiles > catppuccin-mocha${C_RESET}"
}

# --- Tilix theme ---
_theme_tilix() {
    if ! command -v dconf &>/dev/null; then
        install_packages dconf-cli
    fi

    if $DRY_RUN; then
        log_dry "Would create Tilix Catppuccin Mocha profile via dconf"
        return 0
    fi

    local profile_id
    profile_id="$(run_as_user "dconf list /com/gexperts/Tilix/profiles/" 2>/dev/null | head -1 | tr -d '/')"

    if [[ -z "${profile_id}" ]]; then
        log_warn "Tilix: No profile found. Create one first, then re-run."
        return 0
    fi

    local dconf_path="/com/gexperts/Tilix/profiles/${profile_id}"

    local current_bg
    current_bg="$(run_as_user "dconf read ${dconf_path}/background-color" 2>/dev/null || echo "")"
    if [[ "${current_bg}" == *"1E1E2E"* ]]; then
        log_info "Tilix already has Catppuccin Mocha."
        return 0
    fi

    run_as_user "dconf write ${dconf_path}/background-color \"${CM_BG}\""
    run_as_user "dconf write ${dconf_path}/foreground-color \"${CM_FG}\""
    run_as_user "dconf write ${dconf_path}/cursor-background-color \"${CM_CURSOR}\""
    run_as_user "dconf write ${dconf_path}/cursor-foreground-color \"${CM_BG}\""
    run_as_user "dconf write ${dconf_path}/use-theme-colors false"

    local palette="[${CM_BLACK}, ${CM_RED}, ${CM_GREEN}, ${CM_YELLOW}, ${CM_BLUE}, ${CM_MAGENTA}, ${CM_CYAN}, ${CM_WHITE}, ${CM_BRBLACK}, ${CM_BRRED}, ${CM_BRGREEN}, ${CM_BRYELLOW}, ${CM_BRBLUE}, ${CM_BRMAGENTA}, ${CM_BRCYAN}, ${CM_BRWHITE}]"
    run_as_user "dconf write ${dconf_path}/palette \"${palette}\""

    log_info "Tilix: Catppuccin Mocha applied to profile ${profile_id}."
}

# --- Theme dispatcher ---
apply_terminal_themes() {
    log_step "Applying Catppuccin Mocha theme to detected terminals..."

    local applied=0

    declare -A terminal_map=(
        [alacritty]="_theme_alacritty"
        [kitty]="_theme_kitty"
        [gnome-terminal]="_theme_gnome_terminal"
        [xfce4-terminal]="_theme_xfce_terminal"
        [konsole]="_theme_konsole"
        [foot]="_theme_foot"
        [wezterm]="_theme_wezterm"
        [terminator]="_theme_terminator"
        [tilix]="_theme_tilix"
    )

    for term_cmd in "${!terminal_map[@]}"; do
        if command -v "${term_cmd}" &>/dev/null; then
            log_info "Detected: ${C_BOLD}${term_cmd}${C_RESET}"
            "${terminal_map[$term_cmd]}"
            applied=$((applied + 1))
        else
            log_debug "Not found: ${term_cmd}"
        fi
    done

    if (( applied == 0 )); then
        log_warn "No supported terminal emulators detected."
    else
        log_info "Catppuccin Mocha applied to ${applied} terminal(s)."
    fi
}

#===============================================================================
# SET NERD FONT IN TERMINALS
#===============================================================================

_set_font_alacritty() {
    local family="$1" size="$2"
    local config_dir="${TARGET_HOME}/.config/alacritty"
    local config_toml="${config_dir}/alacritty.toml"
    local config_yml="${config_dir}/alacritty.yml"

    if $DRY_RUN; then log_dry "Would set Alacritty font to ${family} ${size}"; return 0; fi

    if [[ -f "${config_toml}" ]]; then
        if grep -qE '^\[font\]' "${config_toml}" 2>/dev/null; then
            if grep -qE '^\s*size\s*=' "${config_toml}" 2>/dev/null; then
                sed -i "s|^\(\s*\)size\s*=.*|\1size = ${size}|" "${config_toml}"
            fi
            if grep -qE '^\s*family\s*=' "${config_toml}" 2>/dev/null; then
                sed -i "s|^\(\s*\)family\s*=.*|\1family = \"${family}\"|" "${config_toml}"
            else
                sed -i "/^\[font\.normal\]/a family = \"${family}\"" "${config_toml}"
            fi
        else
            {
                echo ""
                echo "[font]"
                echo "size = ${size}"
                echo ""
                echo "[font.normal]"
                echo "family = \"${family}\""
            } >> "${config_toml}"
        fi
        log_info "Alacritty: font -> ${family} ${size}"
    elif [[ -f "${config_yml}" ]]; then
        if grep -qE '^\s*family:' "${config_yml}" 2>/dev/null; then
            sed -i "s|^\(\s*\)family:.*|\1family: ${family}|" "${config_yml}"
        else
            {
                echo ""
                echo "font:"
                echo "  normal:"
                echo "    family: ${family}"
                echo "  size: ${size}"
            } >> "${config_yml}"
        fi
        log_info "Alacritty (yml): font -> ${family} ${size}"
    else
        run_as_user "mkdir -p '${config_dir}'"
        run_as_user "cat > '${config_toml}' << ALEOF
[font]
size = ${size}

[font.normal]
family = \"${family}\"
ALEOF"
        log_info "Alacritty: created config with ${family} ${size}"
    fi
}

_set_font_kitty() {
    local family="$1" size="$2"
    local config="${TARGET_HOME}/.config/kitty/kitty.conf"

    if $DRY_RUN; then log_dry "Would set Kitty font to ${family} ${size}"; return 0; fi

    run_as_user "mkdir -p '${TARGET_HOME}/.config/kitty'"
    [[ -f "${config}" ]] || run_as_user "touch '${config}'"

    if grep -qE '^\s*font_family\s' "${config}" 2>/dev/null; then
        sed -i "s|^\s*font_family\s.*|font_family ${family}|" "${config}"
    else
        run_as_user "echo 'font_family ${family}' >> '${config}'"
    fi

    if grep -qE '^\s*font_size\s' "${config}" 2>/dev/null; then
        sed -i "s|^\s*font_size\s.*|font_size ${size}|" "${config}"
    else
        run_as_user "echo 'font_size ${size}' >> '${config}'"
    fi

    log_info "Kitty: font -> ${family} ${size}"
}

_set_font_gnome_terminal() {
    local family="$1" size="$2"

    if ! command -v dconf &>/dev/null; then return 0; fi
    if $DRY_RUN; then log_dry "Would set GNOME Terminal font to ${family} ${size}"; return 0; fi

    local profiles
    profiles="$(run_as_user "dconf list /org/gnome/terminal/legacy/profiles:/" 2>/dev/null | grep '^:' || true)"

    if [[ -z "${profiles}" ]]; then
        log_debug "GNOME Terminal: no profiles found"
        return 0
    fi

    local font_string="${family} ${size}"
    while IFS= read -r profile; do
        local path="/org/gnome/terminal/legacy/profiles:/${profile}"
        run_as_user "dconf write ${path}font \"'${font_string}'\""
        run_as_user "dconf write ${path}use-system-font false"
    done <<< "${profiles}"

    log_info "GNOME Terminal: font -> ${font_string}"
}

_set_font_xfce_terminal() {
    local family="$1" size="$2"
    local config="${TARGET_HOME}/.config/xfce4/terminal/terminalrc"

    if $DRY_RUN; then log_dry "Would set XFCE Terminal font to ${family} ${size}"; return 0; fi

    if [[ ! -f "${config}" ]]; then
        log_debug "XFCE Terminal: no terminalrc found"
        return 0
    fi

    local font_string="${family} ${size}"
    _xfce_set_key "${config}" "FontName" "${font_string}"
    _xfce_set_key "${config}" "FontUseSystem" "FALSE"

    log_info "XFCE Terminal: font -> ${font_string}"
}

_set_font_konsole() {
    local family="$1" size="$2"
    local profile_dir="${TARGET_HOME}/.local/share/konsole"

    if $DRY_RUN; then log_dry "Would set Konsole font to ${family} ${size}"; return 0; fi

    local default_profile
    default_profile="$(find "${profile_dir}" -maxdepth 1 -name '*.profile' 2>/dev/null | head -1)"

    if [[ -z "${default_profile}" ]]; then
        log_debug "Konsole: no .profile found"
        return 0
    fi

    local font_entry="${family},${size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

    if grep -qE '^\s*Font=' "${default_profile}" 2>/dev/null; then
        sed -i "s|^\s*Font=.*|Font=${font_entry}|" "${default_profile}"
    else
        if grep -q '\[Appearance\]' "${default_profile}" 2>/dev/null; then
            sed -i "/^\[Appearance\]/a Font=${font_entry}" "${default_profile}"
        else
            echo -e "\n[Appearance]\nFont=${font_entry}" >> "${default_profile}"
        fi
    fi

    log_info "Konsole: font -> ${family} ${size}"
}

_set_font_foot() {
    local family="$1" size="$2"
    local config="${TARGET_HOME}/.config/foot/foot.ini"

    if $DRY_RUN; then log_dry "Would set Foot font to ${family} ${size}"; return 0; fi

    if [[ ! -f "${config}" ]]; then
        log_debug "Foot: no config found"
        return 0
    fi

    local font_line="font=${family}:size=${size}"

    if grep -qE '^\s*font=' "${config}" 2>/dev/null; then
        sed -i "s|^\s*font=.*|${font_line}|" "${config}"
    else
        if grep -q '\[main\]' "${config}" 2>/dev/null; then
            sed -i "/^\[main\]/a ${font_line}" "${config}"
        else
            local tmp; tmp="$(mktemp)"
            { echo "[main]"; echo "${font_line}"; echo ""; cat "${config}"; } > "${tmp}"
            run_as_user "cp '${tmp}' '${config}'"
            rm -f "${tmp}"
        fi
    fi

    log_info "Foot: font -> ${family} ${size}"
}

_set_font_wezterm() {
    local family="$1" size="$2"
    local config="${TARGET_HOME}/.config/wezterm/wezterm.lua"

    if $DRY_RUN; then log_dry "Would set WezTerm font to ${family} ${size}"; return 0; fi

    if [[ ! -f "${config}" ]]; then
        log_debug "WezTerm: no config found"
        return 0
    fi

    if grep -qE '^\s*config\.font_size' "${config}" 2>/dev/null; then
        sed -i "s|^\s*config\.font_size.*|config.font_size = ${size}|" "${config}"
    else
        sed -i "/^return config/i config.font_size = ${size}" "${config}"
    fi

    local font_lua="config.font = wezterm.font(\"${family}\")"
    if grep -qE '^\s*config\.font\s*=' "${config}" 2>/dev/null; then
        sed -i "s|^\s*config\.font\s*=.*|${font_lua}|" "${config}"
    else
        sed -i "/^return config/i ${font_lua}" "${config}"
    fi

    log_info "WezTerm: font -> ${family} ${size}"
}

_set_font_terminator() {
    local family="$1" size="$2"
    local config="${TARGET_HOME}/.config/terminator/config"

    if $DRY_RUN; then log_dry "Would set Terminator font to ${family} ${size}"; return 0; fi

    if [[ ! -f "${config}" ]]; then
        log_debug "Terminator: no config found"
        return 0
    fi

    local font_string="${family} ${size}"

    if grep -qE '^\s*font\s*=' "${config}" 2>/dev/null; then
        sed -i "s|^\(\s*\)font\s*=.*|\1font = ${font_string}|" "${config}"
    else
        sed -i "/\[\[default\]\]/a \\      font = ${font_string}" "${config}" 2>/dev/null || \
        sed -i "/\[profiles\]/a \\    font = ${font_string}" "${config}"
    fi

    if grep -qE '^\s*use_system_font' "${config}" 2>/dev/null; then
        sed -i "s|^\(\s*\)use_system_font.*|\1use_system_font = False|" "${config}"
    fi

    log_info "Terminator: font -> ${font_string}"
}

_set_font_tilix() {
    local family="$1" size="$2"

    if ! command -v dconf &>/dev/null; then return 0; fi
    if $DRY_RUN; then log_dry "Would set Tilix font to ${family} ${size}"; return 0; fi

    local profile_id
    profile_id="$(run_as_user "dconf list /com/gexperts/Tilix/profiles/" 2>/dev/null | head -1 | tr -d '/')"

    if [[ -z "${profile_id}" ]]; then
        log_debug "Tilix: no profile found"
        return 0
    fi

    local dconf_path="/com/gexperts/Tilix/profiles/${profile_id}"
    local font_string="${family} ${size}"

    run_as_user "dconf write ${dconf_path}/font \"'${font_string}'\""
    run_as_user "dconf write ${dconf_path}/use-system-font false"

    log_info "Tilix: font -> ${font_string}"
}

# --- Font dispatcher ---
set_terminal_font() {
    [[ -z "${FONT_NAME}" ]] && return 0
    log_step "Setting Nerd Font in detected terminals..."

    local font_family
    font_family="$(_nerd_font_family "${FONT_NAME}")"
    local font_size="12"
    local applied=0

    log_info "Font family: ${C_BOLD}${font_family}${C_RESET}"

    declare -A font_terminal_map=(
        [alacritty]="_set_font_alacritty"
        [kitty]="_set_font_kitty"
        [gnome-terminal]="_set_font_gnome_terminal"
        [xfce4-terminal]="_set_font_xfce_terminal"
        [konsole]="_set_font_konsole"
        [foot]="_set_font_foot"
        [wezterm]="_set_font_wezterm"
        [terminator]="_set_font_terminator"
        [tilix]="_set_font_tilix"
    )

    for term_cmd in "${!font_terminal_map[@]}"; do
        if command -v "${term_cmd}" &>/dev/null; then
            "${font_terminal_map[$term_cmd]}" "${font_family}" "${font_size}"
            applied=$((applied + 1))
        fi
    done

    if (( applied == 0 )); then
        log_warn "No terminals detected for font configuration."
    else
        log_info "Nerd Font set in ${applied} terminal(s)."
    fi
}

#===============================================================================
# ZSHRC CONFIGURATION
#===============================================================================

configure_zshrc() {
    log_step "Configuring .zshrc..."
    local zshrc="${TARGET_HOME}/.zshrc"

    # Backup with timestamp
    if [[ -f "${zshrc}" ]]; then
        local backup="${zshrc}.bak.${TIMESTAMP}"
        log_info "Backup: ${backup}"
        run "cp '${zshrc}' '${backup}'"
        run "chown ${TARGET_USER}:${TARGET_USER} '${backup}'"
    fi

    if $DRY_RUN; then
        log_dry "Would configure plugins + Starship in .zshrc"
        return 0
    fi

    # --- Update plugins line ---
    local desired_plugins="plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)"

    if [[ -f "${zshrc}" ]]; then
        if grep -qE '^\s*plugins=\(' "${zshrc}"; then
            sed -i "s|^[[:space:]]*plugins=(.*)|${desired_plugins}|" "${zshrc}"
            log_info "Updated plugins line."
        else
            echo "" >> "${zshrc}"
            echo "${desired_plugins}" >> "${zshrc}"
            log_info "Added plugins line."
        fi
    else
        log_warn ".zshrc not found — Oh My Zsh should have created it."
    fi

    # --- Desactivar ZSH_THEME (conflicta con Starship) ---
    if grep -qE '^\s*ZSH_THEME=' "${zshrc}" 2>/dev/null; then
        sed -i 's|^[[:space:]]*ZSH_THEME=|# ZSH_THEME=|' "${zshrc}"
        log_info "Commented out ZSH_THEME (conflicts with Starship)."
    fi

    # --- Starship init (idempotent) ---
    if ! grep -qF 'starship init zsh' "${zshrc}" 2>/dev/null; then
        {
            echo ""
            echo "# Starship prompt"
            echo 'eval "$(starship init zsh)"'
        } >> "${zshrc}"
        log_info "Added Starship init."
    else
        log_info "Starship init already present."
    fi

    run "chown ${TARGET_USER}:${TARGET_USER} '${zshrc}'"
}

#===============================================================================
# DEFAULT SHELL
#===============================================================================

set_default_shell() {
    if ! $SET_DEFAULT_SHELL; then
        log_info "Skipping shell change (--no-set-default-shell)."
        return 0
    fi
    log_step "Setting Zsh as default shell for ${TARGET_USER}..."

    local zsh_path
    zsh_path="$(command -v zsh)"
    local current_shell
    current_shell="$(getent passwd "${TARGET_USER}" | cut -d: -f7)"

    if [[ "${current_shell}" == "${zsh_path}" ]]; then
        log_info "Zsh already default."
        return 0
    fi

    if ! grep -qF "${zsh_path}" /etc/shells 2>/dev/null; then
        log_info "Adding ${zsh_path} to /etc/shells"
        run "echo '${zsh_path}' >> /etc/shells"
    fi

    run "chsh -s '${zsh_path}' '${TARGET_USER}'"
    log_info "Default shell -> ${zsh_path}"
}

#===============================================================================
# CLEANUP & SUMMARY
#===============================================================================

cleanup() {
    log_debug "Cleaning temp files..."
    rm -rf /tmp/nerd-font-* 2>/dev/null || true
}

show_summary() {
    echo ""
    echo -e "${C_BOLD}======================================================${C_RESET}"
    echo -e "${C_GREEN}  Terminal setup complete!${C_RESET}"
    echo -e "${C_BOLD}======================================================${C_RESET}"
    echo ""
    echo -e "  ${C_CYAN}User:${C_RESET}       ${TARGET_USER}"
    echo -e "  ${C_CYAN}Zsh:${C_RESET}        $(zsh --version 2>/dev/null || echo 'N/A')"
    echo -e "  ${C_CYAN}Oh My Zsh:${C_RESET}  ${TARGET_HOME}/.oh-my-zsh"
    echo -e "  ${C_CYAN}Starship:${C_RESET}   $(starship --version 2>/dev/null | head -1 || echo 'N/A')"
    echo -e "  ${C_CYAN}Preset:${C_RESET}     catppuccin-powerline"
    if ! $SKIP_FONTS && [[ -n "${FONT_NAME}" ]]; then
        local display_family
        display_family="$(_nerd_font_family "${FONT_NAME}")"
        echo -e "  ${C_CYAN}Font:${C_RESET}       ${display_family}"
    fi
    echo -e "  ${C_CYAN}Theme:${C_RESET}      Catppuccin Mocha"
    echo ""
    echo -e "  ${C_YELLOW}-> Log out/in (or run 'zsh') to activate.${C_RESET}"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================
main() {
    parse_args "$@"

    echo ""
    echo -e "${C_BOLD}${C_CYAN}+===============================================+${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}|  Modern Terminal Setup v${SCRIPT_VERSION}                  |${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}|  Zsh + Oh My Zsh + Starship + Nerd Fonts     |${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}|  + Catppuccin Mocha Theming                  |${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}+===============================================+${C_RESET}"
    echo ""

    detect_pkg_manager
    check_prereqs
    install_zsh
    install_ohmyzsh
    install_ohmyzsh_plugins
    install_starship
    configure_starship
    install_nerd_font
    apply_terminal_themes
    set_terminal_font
    configure_zshrc
    set_default_shell
    cleanup

    if ! $DRY_RUN; then
        show_summary
    else
        echo ""
        log_dry "Dry run complete. No changes made."
    fi
}

main "$@"