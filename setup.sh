#!/bin/bash

# --- COLORES Y ESTÉTICA ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- RUTAS ---
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_SOURCE="$BASE_DIR/config"
TARGET_CONFIG="$HOME/.config"
FONT_DIR="$HOME/.local/share/fonts"

# --- LISTA DE PAQUETES A INSTALAR (Basado en tu .config) ---
DEPENDENCIES=(
    # --- Entorno Gráfico (Window Manager) ---
    "i3-wm" "i3status" "i3lock" "dunst" "picom" "rofi" "polybar" "feh" "libnotify-bin"
    
    # --- Terminal y Shell ---
    "kitty" "fish" "ranger" "fastfetch" "htop"
    
    # --- Sistema de Archivos y Apariencia ---
    "thunar" "lxappearance" "qt5ct" "qt6-qpa-plugins" "qt5-style-kvantum" "papirus-icon-theme" "fonts-font-awesome"
    
    # --- Audio y Multimedia ---
    "pulseaudio" "pavucontrol" "playerctl" "cava" "cmus" "vlc" "gimp"
    
    # --- Utilidades del Sistema ---
    "curl" "wget" "git" "unzip" "build-essential" "maim" "xclip"
)

echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}   INSTALADOR AUTOMÁTICO DE RICE (DEBIAN)     ${NC}"
echo -e "${CYAN}==============================================${NC}"

# 1. ACTUALIZAR SISTEMA
echo -e "${BLUE}[1/6] Actualizando repositorios...${NC}"
sudo apt update

# 2. INSTALACIÓN DE DEPENDENCIAS (Tu lista)
echo -e "${BLUE}[2/6] Instalando dependencias generales...${NC}"
for pkg in "${DEPENDENCIES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo -e "${GREEN}  [OK] $pkg ya instalado.${NC}"
    else
        echo -e "${YELLOW}  [..] Instalando $pkg...${NC}"
        sudo apt install -y "$pkg"
    fi
done

# 3. INSTALACIÓN DE SPOTIFY (Específico para Debian)
# Requerido para tu módulo de Polybar
if dpkg -l | grep -q "spotify-client"; then
    echo -e "${GREEN}  [OK] Spotify ya instalado.${NC}"
else
    echo -e "${BLUE}[3/6] Instalando Spotify Client...${NC}"
    curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt update && sudo apt install -y spotify-client
fi

# 4. INSTALACIÓN DE FUENTES (Nerd Fonts)
echo -e "${BLUE}[4/6] Configurando Fuentes (JetBrainsMono Nerd Font)...${NC}"
FONT_NAME="JetBrainsMono"
if [ -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    echo -e "${GREEN}  [OK] Fuentes detectadas.${NC}"
else
    mkdir -p "$FONT_DIR"
    curl -fLo "/tmp/$FONT_NAME.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_NAME.zip
    unzip -o "/tmp/$FONT_NAME.zip" -d "$FONT_DIR" > /dev/null
    rm "/tmp/$FONT_NAME.zip"
    fc-cache -f -v > /dev/null
    echo -e "${GREEN}  [OK] Fuentes instaladas.${NC}"
fi

# 5. DESPLIEGUE DE DOTFILES (Tus configuraciones)
echo -e "${BLUE}[5/6] Instalando tus configuraciones (Dotfiles)...${NC}"

if [ -d "$DOTFILES_SOURCE" ]; then
    for folder in "$DOTFILES_SOURCE"/*; do
        folder_name=$(basename "$folder")
        dest="$TARGET_CONFIG/$folder_name"
        
        # Si existe, hacer backup
        if [ -d "$dest" ]; then
            echo -e "${YELLOW}  [!] Backup realizado de: $folder_name${NC}"
            mv "$dest" "${dest}_backup_$(date +%s)"
        fi
        
        # Copiar
        cp -r "$folder" "$TARGET_CONFIG/"
        echo -e "${GREEN}  [+] Configuración de $folder_name instalada.${NC}"
    done
else
    echo -e "${RED}[ERROR] No se encontró la carpeta 'config' junto al script.${NC}"
    echo -e "${RED}Asegúrate de copiar tus carpetas de .config dentro de una carpeta 'config' junto a este script.${NC}"
fi

# 6. INYECCIÓN DEL SCRIPT MPRIS (Música)
# Creamos/Sobrescribimos el script player_status.sh para asegurar que tenga los botones nuevos
echo -e "${BLUE}[6/6] Finalizando detalles (Script Player Status)...${NC}"
mkdir -p "$TARGET_CONFIG/polybar/scripts"

cat << 'EOF' > "$TARGET_CONFIG/polybar/scripts/player_status.sh"
#!/bin/bash
COLOR_PLAYER="%{F#00FFFF}" 
COLOR_RESET="%{F-}"

# Obtener nombre del reproductor
PLAYER=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

if [ -z "$PLAYER" ]; then
    echo "%{F#FF0000} Offline%{F-}"
    exit 0
fi

# Formatear nombres
case "$PLAYER" in
    "spotify")   PLAYER_NAME="Spotify" ;;
    "firefox")   PLAYER_NAME="YouTube/Web" ;;
    "chrome")    PLAYER_NAME="Chrome" ;;
    "brave")     PLAYER_NAME="Brave" ;;
    *)           PLAYER_NAME="${PLAYER^}" ;;
esac

# Estado para icono
STATUS=$(playerctl status 2>/dev/null)
if [ "$STATUS" = "Playing" ]; then
    TOGGLE_ICON=""
else
    TOGGLE_ICON=""
fi

# Salida con acciones
echo "${COLOR_PLAYER} ${PLAYER_NAME}${COLOR_RESET} | %{A1:playerctl previous:}%{A}  %{A1:playerctl play-pause:}${TOGGLE_ICON}%{A}  %{A1:playerctl next:}%{A}"
EOF

chmod +x "$TARGET_CONFIG/polybar/scripts/player_status.sh"

# Permisos adicionales para i3/polybar
chmod +x "$TARGET_CONFIG/polybar/launch.sh" 2>/dev/null || true
chmod +x "$TARGET_CONFIG/i3/config" 2>/dev/null || true

echo -e "${CYAN}==============================================${NC}"
echo -e "${GREEN}   ¡INSTALACIÓN COMPLETADA! DISFRUTA TU RICE  ${NC}"
echo -e "${CYAN}==============================================${NC}"
echo "Nota: Si usas Fish shell, recuerda cambiarla con: chsh -s /usr/bin/fish"
echo "Reinicia la sesión para aplicar todos los cambios."
