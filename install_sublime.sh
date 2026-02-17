#!/bin/bash

# Instalar la clave GPG de Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null

# Agregar el repositorio estable de Sublime Text
echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | sudo tee /etc/apt/sources.list.d/sublime-text.sources

# Actualizar los repositorios
sudo apt-get update

# Instalar Sublime Text
sudo apt-get install -y sublime-text

# Detectar el shell actual y configurar el alias
SHELL_NAME=$(basename "$SHELL")

if [ "$SHELL_NAME" = "bash" ]; then
    ALIAS_FILE="$HOME/.bash_aliases"
    echo "\n# Alias para Sublime Text" >> "$ALIAS_FILE"
    echo "alias subl='sublime-text'" >> "$ALIAS_FILE"
    source "$ALIAS_FILE"
elif [ "$SHELL_NAME" = "zsh" ]; then
    ALIAS_FILE="$HOME/.zshrc"
    echo "\n# Alias para Sublime Text" >> "$ALIAS_FILE"
    echo "alias subl='sublime-text'" >> "$ALIAS_FILE"
    source "$ALIAS_FILE"
else
    echo "No se detectó Bash ni Zsh. Añade el alias manualmente a tu archivo de configuración."
fi

echo "Sublime Text ha sido instalado correctamente. Puedes usar 'subl' para abrirlo desde la terminal."
