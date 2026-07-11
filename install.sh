#!/bin/bash

# -> Installation Script for my Kill Bill themed Sway dots.                  

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Functions
info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
success() { echo -e "${GREEN}[OK]${NC}      $1"; }
warn()    { echo -e "${YELLOW}[UYARI]${NC}  $1"; }
error()   { echo -e "${RED}[HATA]${NC}   $1"; }
section() { echo -e "\n${MAGENTA}${BOLD}━━━ $1 ━━━${NC}"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
BACKUP_DIR="${HOME}/.config/sway-dots-backup/$(date +%Y%m%d_%H%M%S)"

# Themes
CURSOR_THEME="Graphite-dark-cursors"
GTK_THEME="Graphite-yellow-Dark"
ICON_THEME_LIGHT="Vimix-amber"
ICON_THEME_DARK="Vimix-amber-dark"

# Banner
echo -e "${YELLOW}${BOLD}"
cat << 'EOF'
   ______      ______ __  __     ____        __
  / ___/ | /| / / __ `/ / / /   / __ \____  / /______
  \__ \| |/ |/ / /_/ / /_/ /   / / / / __ \/ __/ ___/
 ___/ /|__/|__/\__,_/\__, /   / /_/ / /_/ / /_(__  )
/____/              /____/   /_____/\____/\__/____/
EOF
echo -e "${NC}"
echo -e "${CYAN}  Kill Bill themed Sway dots.${NC}"
echo -e "${CYAN}  ──────────────────────────────────────────────────────────${NC}\n"


# Package installation - Distro Selection

# Automated distro detection.
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            opensuse*|suse*) echo "opensuse" ;;
            arch|manjaro|endeavouros|garuda) echo "arch" ;;
            fedora|nobara) echo "fedora" ;;
            debian|ubuntu|linuxmint|pop|zorin|elementary) echo "debian" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

DETECTED_DISTRO="$(detect_distro)"

# Choosing Distro
echo -e "${BOLD}  Dağıtım seçin (paket yöneticisi):${NC}"
echo ""

if [ "$DETECTED_DISTRO" != "unknown" ]; then
    info "Algılanan dağıtım: ${BOLD}${DETECTED_DISTRO}${NC}"
    echo ""
fi

echo -e "    ${YELLOW}1)${NC} openSUSE      ${CYAN}(zypper)${NC}"
echo -e "    ${YELLOW}2)${NC} Arch Linux    ${CYAN}(pacman)${NC}"
echo -e "    ${YELLOW}3)${NC} Fedora        ${CYAN}(dnf)${NC}"
echo -e "    ${YELLOW}4)${NC} Debian/Ubuntu ${CYAN}(apt)${NC}"
echo -e "    ${YELLOW}5)${NC} Skip the package installation, I will install the needed packages manually."
echo ""

read -rp "  Your Choice? [1-5]: " distro_choice

case "$distro_choice" in
    1) DISTRO="opensuse" ;;
    2) DISTRO="arch" ;;
    3) DISTRO="fedora" ;;
    4) DISTRO="debian" ;;
    5) DISTRO="skip" ;;
    *)
        if [ "$DETECTED_DISTRO" != "unknown" ]; then
            DISTRO="$DETECTED_DISTRO"
            info "Using detected distro: $DISTRO"
        else
            warn "Invalid choice, skipping..."
            DISTRO="skip"
        fi
        ;;
esac

# Package Installation
MANUAL_PKGS=()

if [ "$DISTRO" != "skip" ]; then
    section "Package Installation ($DISTRO)"

    case "$DISTRO" in
        opensuse)
            info "Installing packages with zypper"
            PKGS=(sway swaybg swaylock swayidle swaynag kitty waybar fish mako fuzzel fastfetch brightnessctl playerctl grim slurp swappy clipse calcure wl-clipboard qt5ct qt6ct kvantum-manager pipewire-pulseaudio glib2-tools gtk3-tools xdg-desktop-portal-wlr starship cava)
            if ! sudo zypper install -y --no-recommends "${PKGS[@]}" &>/dev/null; then
                warn "One-line installation didn't install some packages, installing one by one."
                for pkg in "${PKGS[@]}"; do
                    sudo zypper install -y --no-recommends "$pkg" &>/dev/null || MANUAL_PKGS+=("$pkg")
                done
            fi
            success "OpenSUSE packages installed."
            ;;

        arch)
            info "Installing packages with pacman"
            PKGS=(sway swaybg swaylock swayidle kitty waybar fish mako fuzzel fastfetch brightnessctl playerctl grim slurp swappy clipse calcure wl-clipboard qt5ct qt6ct kvantum pipewire-pulse glib2 gtk-update-icon-cache xdg-desktop-portal-wlr starship cava)
            
            if ! sudo pacman -S --needed --noconfirm "${PKGS[@]}" &>/dev/null; then
                warn "One-line installation didn't install some packages, installing one by one."
                FAILED_PACMAN=()
                for pkg in "${PKGS[@]}"; do
                    sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null || FAILED_PACMAN+=("$pkg")
                done
                
                # AUR Packages
                if [ ${#FAILED_PACMAN[@]} -gt 0 ]; then
                    info "Trying to install packages with AUR: ${FAILED_PACMAN[*]}"
                    if command -v yay &>/dev/null; then
                        AUR_HELPER="yay"
                    elif command -v paru &>/dev/null; then
                        AUR_HELPER="paru"
                    fi

                    if [ -n "${AUR_HELPER:-}" ]; then
                        for pkg in "${FAILED_PACMAN[@]}"; do
                            $AUR_HELPER -S --noconfirm "$pkg" &>/dev/null || MANUAL_PKGS+=("$pkg")
                        done
                    else
                        warn "Yay or Paru isn't installed on your system, AUR fallback aborting. "
                        MANUAL_PKGS+=("${FAILED_PACMAN[@]}")
                    fi
                fi
            fi
            success "Arch Linux packages installed."
            ;;

        fedora)
            info "Installing packages with DNF"
            PKGS=(sway swaybg swaylock swayidle kitty waybar fish mako fuzzel fastfetch brightnessctl playerctl grim slurp swappy clipse calcure wl-clipboard qt5ct qt6ct kvantum pipewire-pulseaudio glib2 gtk-update-icon-cache xdg-desktop-portal-wlr starship cava)
            if ! sudo dnf install -y "${PKGS[@]}" &>/dev/null; then
                warn "One-line installation didn't install some packages, installing one by one."
                for pkg in "${PKGS[@]}"; do
                    sudo dnf install -y "$pkg" &>/dev/null || MANUAL_PKGS+=("$pkg")
                done
            fi
            success "Fedora packages installed."
            ;;

        debian)
            info "Installing packages with APT"
            sudo apt update &>/dev/null
            PKGS=(sway swaybg swaylock swayidle kitty waybar fish mako-notifier fuzzel fastfetch brightnessctl playerctl grim slurp swappy clipse calcure wl-clipboard qt5ct kvantum pipewire-pulse libglib2.0-bin gtk-update-icon-cache xdg-desktop-portal-wlr cava)
            if ! sudo apt install -y "${PKGS[@]}" &>/dev/null; then
                warn "One-line installation didn't install some packages, installing one by one."
                for pkg in "${PKGS[@]}"; do
                    sudo apt install -y "$pkg" &>/dev/null || MANUAL_PKGS+=("$pkg")
                done
            fi

            if ! command -v qt6ct &>/dev/null; then
                warn "qt6ct was not found in the repositories."
                MANUAL_PKGS+=("qt6ct")
            fi
            if ! command -v starship &>/dev/null; then
                info "Installing Starship with the official install script."
                curl -sS https://starship.rs/install.sh | sh -s -- -y &>/dev/null \
                    || MANUAL_PKGS+=("starship")
            fi
            success "Debian (or Ubuntu) packages installed."
            ;;
    esac

    echo ""
fi

# Create backup dir
create_backup() {
    local target="$1"
    if [ -e "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name
        backup_name="$(basename "$target")"
        cp -r "$target" "$BACKUP_DIR/$backup_name"
        warn "'$backup_name' backup successfully created at → $BACKUP_DIR/$backup_name"
    fi
}

# Symlink things
link_config() {
    local src="$1"
    local dst="$2"

    create_backup "$dst"
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
    success "$(basename "$dst") → $dst"
}

#  Font Installation
section "Font Installation"

FONT_SRC="${DOTFILES_DIR}/fonts"
FONT_DST="${HOME}/.local/share/fonts"

if [ -d "$FONT_SRC" ]; then
    mkdir -p "$FONT_DST"
    font_count=0

    for font_dir in "$FONT_SRC"/*/; do
        [ -d "$font_dir" ] || continue
        dir_name="$(basename "$font_dir")"
        dst_dir="${FONT_DST}/${dir_name}"

        create_backup "$dst_dir"
        mkdir -p "$dst_dir"

        for font_file in "$font_dir"*.ttf "$font_dir"*.otf "$font_dir"*.TTF "$font_dir"*.OTF; do
            [ -f "$font_file" ] || continue
            cp "$font_file" "$dst_dir/"
            font_count=$((font_count + 1))
        done

        if [ "$font_count" -gt 0 ]; then
            success "${dir_name} fonts are installed → $dst_dir"
        fi
    done

    # Font cache güncelle
    if command -v fc-cache &>/dev/null; then
        info "Updating font cache."
        fc-cache -f 2>/dev/null
        success "Font cache is updated ($font_count fonts installed)"
    else
        warn "fc-cache was not found, font cache needs to be updated manually. You figure that out!"
    fi
else
    warn "Font dir can't be found (Wtf): $FONT_SRC"
fi

# Cursor Theme
section "Cursor Theme: ${CURSOR_THEME}"

CURSOR_SRC="${DOTFILES_DIR}/cursor/${CURSOR_THEME}"
CURSOR_DST_LOCAL="${HOME}/.local/share/icons/${CURSOR_THEME}"
CURSOR_DST_SYSTEM="/usr/share/icons/${CURSOR_THEME}"

if [ -d "$CURSOR_SRC" ]; then
    # Kullanıcı dizinine kur
    create_backup "$CURSOR_DST_LOCAL"
    mkdir -p "${HOME}/.local/share/icons"
    rm -rf "$CURSOR_DST_LOCAL"
    cp -r "$CURSOR_SRC" "$CURSOR_DST_LOCAL"
    success "Cursor Theme is installed → $CURSOR_DST_LOCAL"

    # install it on system dir too. (wayland compatibility)
    if [ -w "/usr/share/icons" ] || [ "$(id -u)" -eq 0 ]; then
        rm -rf "$CURSOR_DST_SYSTEM"
        cp -r "$CURSOR_SRC" "$CURSOR_DST_SYSTEM"
        success "Cursor theme is also installed on your system dir → $CURSOR_DST_SYSTEM"
    else
        warn "Cursor theme didn't install on your system dir, to install it manually: sudo cp -r '${CURSOR_SRC}' '${CURSOR_DST_SYSTEM}'"
    fi

    # Make it default cursor
    mkdir -p "${HOME}/.icons/default"
    cat > "${HOME}/.icons/default/index.theme" << CURSOR_EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=${CURSOR_THEME}
CURSOR_EOF
    success "Now it's default cursor"
else
    error "Cursor Theme can't be found: $CURSOR_SRC"
fi

# Icon pack

section "Icon Pack: ${ICON_THEME_LIGHT} & ${ICON_THEME_DARK}"

ICON_DIR="${HOME}/.local/share/icons"
mkdir -p "$ICON_DIR"

for icon_name in "$ICON_THEME_LIGHT" "$ICON_THEME_DARK"; do
    ICON_SRC="${DOTFILES_DIR}/icon/${icon_name}"
    ICON_DST="${ICON_DIR}/${icon_name}"

    if [ -d "$ICON_SRC" ]; then
        create_backup "$ICON_DST"
        rm -rf "$ICON_DST"
        cp -r "$ICON_SRC" "$ICON_DST"
        success "${icon_name} installed at → $ICON_DST"

        # Icon cache güncelle
        if command -v gtk-update-icon-cache &>/dev/null; then
            gtk-update-icon-cache -f -t "$ICON_DST" 2>/dev/null || true
            success "${icon_name} icon cache refreshed successfully"
        fi
    else
        error "Icon pack can't be found: $ICON_SRC"
    fi
done

# GTK Theme
section "GTK Theme: ${GTK_THEME}"

# ── 3a. GTK tema dosyalarını kur ─────────────────────────────────────
GTK_THEME_SRC="${DOTFILES_DIR}/gtk-theme/${GTK_THEME}"
GTK_THEME_DST_LOCAL="${HOME}/.local/share/themes/${GTK_THEME}"
GTK_THEME_DST_THEMES="${HOME}/.themes/${GTK_THEME}"

if [ -d "$GTK_THEME_SRC" ]; then
    # ~/.local/share/themes'e kur
    create_backup "$GTK_THEME_DST_LOCAL"
    mkdir -p "${HOME}/.local/share/themes"
    rm -rf "$GTK_THEME_DST_LOCAL"
    cp -r "$GTK_THEME_SRC" "$GTK_THEME_DST_LOCAL"
    success "GTK theme installed at → $GTK_THEME_DST_LOCAL"

    # ~/.themes installation for compatibility
    create_backup "$GTK_THEME_DST_THEMES"
    mkdir -p "${HOME}/.themes"
    rm -rf "$GTK_THEME_DST_THEMES"
    cp -r "$GTK_THEME_SRC" "$GTK_THEME_DST_THEMES"
    success "GTK theme installed at → $GTK_THEME_DST_THEMES"
else
    error "GTK dir can't be found: $GTK_THEME_SRC"
fi

# GTK-3.0 Configuration
GTK3_SRC="${DOTFILES_DIR}/gtk-3.0"
GTK3_DST="${CONFIG_DIR}/gtk-3.0"

if [ -d "$GTK3_SRC" ]; then
    # settings.ini backup
    create_backup "$GTK3_DST/settings.ini"
    mkdir -p "$GTK3_DST"
    cp "$GTK3_SRC/settings.ini" "$GTK3_DST/settings.ini"
    success "GTK 3.0 settings.ini → $GTK3_DST/settings.ini"

    # GTK 3.0 theme override files (if they exist)
    if [ -d "$GTK3_SRC/${GTK_THEME}" ]; then
        create_backup "$GTK3_DST/${GTK_THEME}"
        cp -r "$GTK3_SRC/${GTK_THEME}" "$GTK3_DST/${GTK_THEME}"
        success "GTK 3.0 theme override → $GTK3_DST/${GTK_THEME}"
    fi
fi

# GTK 4.0 Configuration
GTK4_SRC="${DOTFILES_DIR}/gtk-4.0"
GTK4_DST="${CONFIG_DIR}/gtk-4.0"

if [ -d "$GTK4_SRC" ]; then
    create_backup "$GTK4_DST/settings.ini"
    mkdir -p "$GTK4_DST"
    cp "$GTK4_SRC/settings.ini" "$GTK4_DST/settings.ini"
    success "GTK 4.0 settings.ini → $GTK4_DST/settings.ini"

    if [ -d "$GTK4_SRC/${GTK_THEME}" ]; then
        create_backup "$GTK4_DST/${GTK_THEME}"
        cp -r "$GTK4_SRC/${GTK_THEME}" "$GTK4_DST/${GTK_THEME}"
        success "GTK 4.0 tema override → $GTK4_DST/${GTK_THEME}"
    fi
fi

# GTK 2.0 Configuration
GTK2RC="${HOME}/.gtkrc-2.0"
info "GTK 2.0 ayarları yazılıyor..."
create_backup "$GTK2RC"
cat > "$GTK2RC" << GTK2_EOF
gtk-theme-name="${GTK_THEME}"
gtk-icon-theme-name="${ICON_THEME_DARK}"
gtk-cursor-theme-name="${CURSOR_THEME}"
gtk-cursor-theme-size=24
gtk-font-name="Noto Sans 11"
GTK2_EOF
success "GTK 2.0 settings created at → $GTK2RC"

# Kvantum theme
section "Kvantum and QT theme configuration"

# Kvantum configuration
KVANTUM_DIR="${CONFIG_DIR}/Kvantum"
mkdir -p "$KVANTUM_DIR"

create_backup "$KVANTUM_DIR/kvantumrc"
cat > "$KVANTUM_DIR/kvantumrc" << KVANTUM_EOF
[General]
theme=GraphiteDarkYellow

[Applications]
GraphiteDarkYellow=Graphite dark yellow, Pair with Graphite-yellow-Dark GTK
KVANTUM_EOF
success "Kvantum yapılandırması → $KVANTUM_DIR/kvantumrc"

if command -v kvantummanager &>/dev/null; then
    success "Kvantum is installed, theme can be applied."
else
    warn "Kvantum isn't installed. Automated QT theming will not happen, install Kvantum and make configurations manually."
fi

# QT5CT configuration.
QT5CT_SRC="${DOTFILES_DIR}/qt5ct"
QT5CT_DST="${CONFIG_DIR}/qt5ct"

if [ -f "$QT5CT_SRC/qt5ct.conf" ]; then
    link_config "$QT5CT_SRC/qt5ct.conf" "$QT5CT_DST/qt5ct.conf"
fi

# QT6CT configuration
QT6CT_SRC="${DOTFILES_DIR}/qt6ct"
QT6CT_DST="${CONFIG_DIR}/qt6ct"

if [ -d "$QT6CT_SRC" ]; then
    # qt6ct.conf
    if [ -f "$QT6CT_SRC/qt6ct.conf" ]; then
        link_config "$QT6CT_SRC/qt6ct.conf" "$QT6CT_DST/qt6ct.conf"
    fi

    # qt6ct renk şeması
    if [ -d "$QT6CT_SRC/colors" ]; then
        mkdir -p "$QT6CT_DST/colors"
        for color_file in "$QT6CT_SRC/colors"/*; do
            if [ -f "$color_file" ]; then
                local_name="$(basename "$color_file")"
                create_backup "$QT6CT_DST/colors/$local_name"
                cp "$color_file" "$QT6CT_DST/colors/$local_name"
                success "Qt6 color scheme: $local_name → $QT6CT_DST/colors/"
            fi
        done
    fi
fi

# Application configurations
section "Application configurations"

# ── Sway ─────────────────────────────────────────────────────────────
SWAY_SRC="${DOTFILES_DIR}/sway"
SWAY_DST="${CONFIG_DIR}/sway"

if [ -d "$SWAY_SRC" ]; then
    create_backup "$SWAY_DST"
    mkdir -p "$SWAY_DST"
    # config dosyalarını kopyala (.save dosyaları hariç)
    for sway_file in "$SWAY_SRC"/config; do
        if [ -f "$sway_file" ]; then
            cp "$sway_file" "$SWAY_DST/"
            success "Sway config → $SWAY_DST/$(basename "$sway_file")"
        fi
    done
fi

# ── Wallpapers ───────────────────────────────────────────────────────
WP_SRC="${DOTFILES_DIR}/wallpapers"
WP_DST="${CONFIG_DIR}/sway/wallpapers"

if [ -d "$WP_SRC" ]; then
    create_backup "$WP_DST"
    mkdir -p "$WP_DST"
    cp "$WP_SRC"/*.{jpg,jpeg,png,webp} "$WP_DST/" 2>/dev/null || true
    wp_count=$(find "$WP_DST" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | wc -l)
    success "${wp_count} wallpaper applied → $WP_DST"
else
    warn "Wallpaper dir can't be found: $WP_SRC"
fi

if [ -d "${DOTFILES_DIR}/waybar" ]; then
    link_config "${DOTFILES_DIR}/waybar" "${CONFIG_DIR}/waybar"
fi

if [ -d "${DOTFILES_DIR}/kitty" ]; then
    link_config "${DOTFILES_DIR}/kitty" "${CONFIG_DIR}/kitty"
fi

if [ -d "${DOTFILES_DIR}/fuzzel" ]; then
    link_config "${DOTFILES_DIR}/fuzzel" "${CONFIG_DIR}/fuzzel"
fi

if [ -d "${DOTFILES_DIR}/mako" ]; then
    link_config "${DOTFILES_DIR}/mako" "${CONFIG_DIR}/mako"
fi

if [ -d "${DOTFILES_DIR}/fastfetch" ]; then
    link_config "${DOTFILES_DIR}/fastfetch" "${CONFIG_DIR}/fastfetch"
fi

if [ -d "${DOTFILES_DIR}/fish" ]; then
    FISH_DST="${CONFIG_DIR}/fish"
    create_backup "$FISH_DST"
    mkdir -p "$FISH_DST"
    # Only copy config and variables.
    for fish_file in config.fish fish_variables; do
        if [ -f "${DOTFILES_DIR}/fish/$fish_file" ]; then
            cp "${DOTFILES_DIR}/fish/$fish_file" "$FISH_DST/$fish_file"
            success "Fish $fish_file → $FISH_DST/$fish_file"
        fi
    done
fi

if [ -f "${DOTFILES_DIR}/starship.toml" ]; then
    create_backup "${CONFIG_DIR}/starship.toml"
    cp "${DOTFILES_DIR}/starship.toml" "${CONFIG_DIR}/starship.toml"
    success "Starship config → ${CONFIG_DIR}/starship.toml"
fi

if [ -d "${DOTFILES_DIR}/cava" ]; then
    link_config "${DOTFILES_DIR}/cava" "${CONFIG_DIR}/cava"
fi


# Environment Variables
section "Environment Variables"

# wayland - qt env
ENV_DIR="${CONFIG_DIR}/environment.d"
ENV_FILE="${ENV_DIR}/sway-dots.conf"
mkdir -p "$ENV_DIR"
create_backup "$ENV_FILE"

cat > "$ENV_FILE" << ENV_EOF
# sway-dots Environment Variables
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=kvantum
XCURSOR_THEME=${CURSOR_THEME}
XCURSOR_SIZE=24
GTK_THEME=${GTK_THEME}
ENV_EOF
success "Environment Variables → $ENV_FILE"

# GSettings Configuration
section "GSettings Configuration"

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null && \
        success "gsettings: gtk-theme = $GTK_THEME" || \
        warn "gtk-theme can't be applied"

    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME_DARK" 2>/dev/null && \
        success "gsettings: icon-theme = $ICON_THEME_DARK" || \
        warn "icon theme can't be applied"

    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null && \
        success "gsettings: cursor-theme = $CURSOR_THEME" || \
        warn "cursor theme can't be applied"

    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null && \
        success "gsettings: cursor-size = 24" || \
        warn "cursor size can't be applied"

    gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11' 2>/dev/null && \
        success "gsettings: font-name = Noto Sans 11" || \
        warn "font name can't be applied"
else
    warn "gsettings can't be found, GTK configuration only made in files."
fi

# Summary
echo ""
echo -e "${YELLOW}${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Installation Completed${NC}"
echo -e "${YELLOW}${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Themes Installed:${NC}"
echo -e "    ${BOLD}GTK Teması:${NC}     ${GTK_THEME}"
echo -e "    ${BOLD}Icon Paketi:${NC}    ${ICON_THEME_DARK} / ${ICON_THEME_LIGHT}"
echo -e "    ${BOLD}Cursor Teması:${NC}  ${CURSOR_THEME}"
echo -e "    ${BOLD}Kvantum:${NC}        GraphiteDarkYellow (QT)"
echo ""
echo -e "${CYAN}  Fonts Installed:${NC}"
echo -e "    Iosevka Nerd Font · JetBrainsMono · Noto Sans · Noto Sans JP · Bebas Neue · Impact"
echo ""
echo -e "${CYAN}  Configurations Applied:${NC}"
echo -e "    sway · waybar · kitty · fuzzel · mako · fastfetch · fish · starship · cava"
echo -e "    qt5ct · qt6ct · GTK 2.0/3.0/4.0 · wallpapers"
echo ""
echo -e "${CYAN}  Yedekler:${NC} ${BACKUP_DIR}"
echo ""

if [ ${#MANUAL_PKGS[@]} -gt 0 ]; then
    echo -e "${RED}${BOLD}  [!] YO YO YO! These packages cannot be installed, so you have to install them manually.${NC}"
    echo -e "${RED}  Build from source, use community repos or just don't use them.${NC}"
    echo -e "    ${BOLD}${MANUAL_PKGS[*]}${NC}"
    echo ""
fi

echo -e "${YELLOW}  Now do these:${NC}"
echo -e "    Reload your sway session: ${BOLD}swaymsg reload${NC}"
echo -e "    And a more guaranteed way: reboot your computer."
echo ""
