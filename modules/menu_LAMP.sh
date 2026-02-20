#/usr/bin/env bash
set -e

# ================= CONFIGURACIÓN =================

declare -A PROJECTS=(
  [facturascripts]="/home/jhon/ProyectosFacturaScripts/"
  [libelula]="/var/www/libelula"
  [libelulaec]="/var/www/libelulaec"
)

APACHE_SERVICE="apache2"
MYSQL_SERVICE="mysql"

# ================= FUNCIONES =================

pause() {
  read -rp "Presiona ENTER para continuar..."
}

enter_project() {
  local name="$1"
  cd "${PROJECTS[$name]}" || exit
  echo "📁 Entraste a $name"
  bash
}

clean_cache() {
  local base="${PROJECTS[$1]}/MyFiles"
  echo "🧹 Limpiando Cache y Tmp en $base"

  [[ -d "$base/Cache" ]] && sudo rm -rf "$base/Cache" && echo "✔ Cache eliminada"
  [[ -d "$base/Tmp" ]] && sudo rm -rf "$base/Tmp" && echo "✔ Tmp eliminada"

  echo "✅ Limpieza completada"
  pause
}

fix_perms() {
  local dir="${PROJECTS[$1]}"
  echo "🔧 Ajustando permisos en $dir"

  sudo chown -R www-data:www-data "$dir"
  sudo find "$dir" -type d -exec chmod 2775 {} \;
  sudo find "$dir" -type f -exec chmod 664 {} \;

  echo "✅ Permisos corregidos"
  pause
}

open_db() {
  read -rp "Usuario MySQL: " DB_USER
  read -rp "Base de datos: " DB_NAME
  mycli -u "$DB_USER" "$DB_NAME"
}

restart_services() {
  echo "🔄 Reiniciando servicios..."
  sudo systemctl restart "$APACHE_SERVICE"
  sudo systemctl restart "$MYSQL_SERVICE"
  sudo systemctl status "$APACHE_SERVICE" --no-pager
  sudo systemctl status "$MYSQL_SERVICE" --no-pager
  pause
}

# ================= MENÚ PRINCIPAL =================

PS3=$'\nSelecciona una opción: '

select option in \
  "Entrar a FacturaScripts" \
  "Entrar a Libelula" \
  "Entrar a LibelulaEC" \
  "Limpiar Cache/Tmp (Libelula)" \
  "Limpiar Cache/Tmp (LibelulaEC)" \
  "Ajustar permisos (Proyecto)" \
  "Abrir Base de Datos (mycli)" \
  "Reiniciar Apache/MySQL" \
  "Salir"; do

  case $REPLY in
    1) enter_project facturascripts ;;
    2) enter_project libelula ;;
    3) enter_project libelulaec ;;
    4) clean_cache libelula ;;
    5) clean_cache libelulaec ;;
    6)
       echo "Proyectos:"
       select p in "${!PROJECTS[@]}"; do
         fix_perms "$p"
         break
       done ;;
    7) open_db ;;
    8) restart_services ;;
    9) echo "👋 Saliendo"; break ;;
    *) echo "❌ Opción inválida" ;;
  esac
done
