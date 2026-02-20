# 📦 Flatpak Cheat Sheet

Flatpak es un sistema de gestión de paquetes universal. Mantiene las aplicaciones aisladas del sistema base (sandboxing).

> [!IMPORTANT]
> **Regla de Oro:** Priorizar siempre los paquetes nativos (`.deb` vía `apt`). Usar Flatpak únicamente si la aplicación no existe en los repositorios oficiales o si se requiere una versión mucho más reciente que la disponible en el sistema.

---

## 1. Instalación de Flatpak

Si la distro no lo incluye por defecto (MX-Linux lo trae, en Mint depende de la edición):

````bash
sudo apt update
sudo apt install flatpak
```
## 2. Configuración de Flathub

Añade el repositorio principal (Flathub) para poder buscar aplicaciones:
```bash

flatpak remote-add --if-not-exists flathub [https://dl.flathub.org/repo/flathub.flatpakrepo](https://dl.flathub.org/repo/flathub.flatpakrepo)
```
Nota: Es necesario reiniciar la sesión para que los iconos de aplicaciones Flatpak aparezcan en el menú de XFCE.
## 3. Buscar aplicaciones

Puedes buscar por nombre o descripción:
```bash

flatpak search nombre_app
```
## 4. Gestión de Aplicaciones (Instalar/Eliminar)
Instalar
```bash

flatpak install flathub org.nombre.App
```
Ejecutar (si no aparece en el menú)
```bash

flatpak run org.nombre.App
```
Eliminar / Remover
```bash

flatpak uninstall org.nombre.App
```
## 5. Limpieza y Optimización

Flatpak puede acumular gigabytes de datos residuales (runtimes antiguos que ya no se usan).
Eliminar datos huérfanos (Runtimes no usados)
```bash

flatpak uninstall --unused
```
Limpiar caché y archivos temporales
```bash

rm -rf ~/.var/app/*/cache/*

Reparar inconsistencias

Si una app no abre o da errores de permisos:
```bash

flatpak repair

💡 Tip para Dotfiles: Permisos (Flatseal)

Si una aplicación Flatpak no puede acceder a tus archivos en ~/Documentos o a tus temas GTK, instala Flatseal. Es la herramienta definitiva para gestionar permisos mediante interfaz gráfica:
```bash

flatpak install flathub com.github.tchx84.Flatseal
````
