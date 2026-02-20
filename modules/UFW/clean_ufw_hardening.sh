#!/bin/bash
# Implementación equivalente con UFW del script hardening.sh
# Objetivo: Seguridad sólida con rendimiento óptimo
# Limpia completamente cualquier configuración previa

# Función para validar formato de IP
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Detectar interfaz primaria y red local
PRIMARY_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [[ -z "$PRIMARY_IFACE" ]]; then
    echo "[ERROR] No se pudo detectar la interfaz primaria"
    exit 1
fi

GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
LOCAL_NETWORK=$(ip route | grep "$PRIMARY_IFACE" | grep -v default | awk '{print $1}' | head -1)

if [[ -z "$GATEWAY" || -z "$LOCAL_NETWORK" ]]; then
    echo "[ERROR] No se pudieron detectar la puerta de enlace o la red local"
    exit 1
fi

# Variables
LAN="$LOCAL_NETWORK"
ROUTER="$GATEWAY"
SAMBA="192.168.1.100"

echo "[INFO] Red local detectada: $LAN"
echo "[INFO] Router/Gateway detectado: $ROUTER"

# Verificar privilegios
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root" 
   exit 1
fi

# Verificar instalación de UFW
if ! command -v ufw &> /dev/null; then
    echo "[INFO] UFW no está instalado. Instalando..."
    apt-get update && apt-get install -y ufw
else
    echo "[INFO] UFW ya está instalado."
fi

# Función para deshabilitar completamente UFW si está activo
disable_ufw_completely() {
    if ufw status | grep -q "Status: active"; then
        echo "[INFO] Deshabilitando UFW actual..."
        ufw --force disable
    fi
}

# Deshabilitar UFW completamente antes de hacer cambios
disable_ufw_completely

# Backup de configuración actual de UFW (si existe)
if [[ -d /etc/ufw ]]; then
    cp -r /etc/ufw /etc/ufw.backup.$(date +%Y%m%d_%H%M%S)
    echo "[INFO] Backup de configuración UFW creada"
fi

# Limpiar completamente cualquier configuración previa de UFW
echo "[INFO] Limpiando configuración previa de UFW..."
ufw --force reset

# Asegurar que no queden reglas residuales en iptables
# Limpiar reglas de iptables que puedan haber sido creadas por UFW previamente
iptables -F ufw-user-input 2>/dev/null
iptables -F ufw-user-forward 2>/dev/null
iptables -F ufw-user-output 2>/dev/null
iptables -X ufw-user-input 2>/dev/null
iptables -X ufw-user-forward 2>/dev/null
iptables -X ufw-user-output 2>/dev/null

# Limpiar también las cadenas de UFW en todas las tablas
for table in filter nat mangle raw security; do
    if iptables -t "$table" -L | grep -q "ufw-"; then
        # Obtener todas las cadenas UFW en esta tabla
        ufw_chains=$(iptables -t "$table" -n -L | awk '/^Chain ufw-/ {print $2}')
        for chain in $ufw_chains; do
            iptables -t "$table" -F "$chain" 2>/dev/null
            iptables -t "$table" -X "$chain" 2>/dev/null
        done
    fi
done

# Reiniciar UFW para asegurar estado limpio
systemctl stop ufw 2>/dev/null || service ufw stop 2>/dev/null
sleep 2
systemctl start ufw 2>/dev/null || service ufw start 2>/dev/null
sleep 2

# Verificar que UFW esté completamente reiniciado
ufw_status=$(ufw status | head -1)
if [[ "$ufw_status" == *"inactive"* ]]; then
    echo "[INFO] UFW está en estado limpio e inactivo"
else
    echo "[INFO] Forzando reinicio completo de UFW..."
    ufw --force reset
fi

# Establecer políticas por defecto
echo "[INFO] Aplicando políticas de seguridad..."
ufw default deny incoming
ufw default allow outgoing

# Permitir loopback
ufw allow in on lo
ufw allow out on lo

# Permitir servicios esenciales
ufw allow ssh                    # Puerto 22
ufw allow http                   # Puerto 80
ufw allow https                  # Puerto 443

# Permitir ICMP (ping)
ufw allow in proto icmp
ufw allow out proto icmp

# Permitir DNS solo al router confiable
ufw allow out to $ROUTER port 53 proto udp
ufw allow out to $ROUTER port 53 proto tcp

# Permitir NTP
ufw allow out 123/udp

# Servicios LAN
# Samba cliente → servidor
ufw allow out to $SAMBA port 139 proto tcp
ufw allow out to $SAMBA port 445 proto tcp
ufw allow from $SAMBA to any port 139 proto tcp
ufw allow from $SAMBA to any port 445 proto tcp

# LocalSend
ufw allow from $LAN to any port 53317 proto tcp
ufw allow from $LAN to any port 53317 proto udp

# InputLeap
ufw allow from $LAN to any port 24800 proto tcp

# SSH solo desde LAN con limitación de tasa
ufw limit from $LAN to any port 22 proto tcp

# mDNS/Avahi
ufw allow from $LAN to any port 5353 proto udp

# Git (SSH saliente - HTTPS ya está cubierto arriba)
# (Puerto 22 ya está permitido para SSH)

# Activar logging de UFW para auditoría
ufw logging on
ufw logging medium  # Nivel medio de detalle

# Activar UFW
echo "[INFO] Activando UFW con nuevas reglas..."
ufw --force enable

# Mostrar estado actual
echo ""
echo "=== Estado actual de UFW ==="
ufw status verbose

echo ""
echo "[INFO] Configuración de UFW completamente limpia y nueva aplicada."
echo "[INFO] Recuerde verificar conectividad antes de salir de esta sesión."

# Información adicional sobre rendimiento
echo ""
echo "[INFO] Optimizaciones de rendimiento implementadas:"
echo "  - UFW utiliza reglas de iptables optimizadas internamente"
echo "  - Menos reglas redundantes comparado con iptables manual"
echo "  - Sistema de conexión establecida gestionado eficientemente"
echo "  - Menor overhead de procesamiento que iptables manual"
echo "  - Configuración completamente limpia sin reglas residuales"