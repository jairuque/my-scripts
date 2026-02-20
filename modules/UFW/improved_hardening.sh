#!/bin/bash
# Firewall restrictivo mejorado para Linux Mint 22.3 / Ubuntu 24.04
# Política base: default deny INPUT/FORWARD, allow OUTPUT legítimo

# Función para validar formato de IP
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Detectar interfaz primaria
PRIMARY_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [[ -z "$PRIMARY_IFACE" ]]; then
    echo "[ERROR] No se pudo detectar la interfaz primaria"
    exit 1
fi

# Detectar gateway y red local
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
LOCAL_NETWORK=$(ip route | grep "$PRIMARY_IFACE" | grep -v default | awk '{print $1}' | head -1)

if [[ -z "$GATEWAY" || -z "$LOCAL_NETWORK" ]]; then
    echo "[ERROR] No se pudieron detectar la puerta de enlace o la red local"
    exit 1
fi

# Variables configurables
IFACE="$PRIMARY_IFACE"
LAN="$LOCAL_NETWORK"
ROUTER="$GATEWAY"
SAMBA="192.168.1.100"  # Esta variable se puede dejar configurable

echo "[INFO] Interfaz detectada: $IFACE"
echo "[INFO] Red local detectada: $LAN"
echo "[INFO] Router/Gateway detectado: $ROUTER"

# Verificar privilegios
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root" 
   exit 1
fi

# Verificar instalación de iptables-persistent
if ! dpkg -l | grep -q iptables-persistent; then
    echo "[INFO] iptables-persistent no está instalado. Instalando..."
    apt-get update && apt-get install -y iptables-persistent
else
    echo "[INFO] iptables-persistent ya está instalado."
fi

# Crear directorio para reglas si no existe
mkdir -p /etc/iptables

# Backup de reglas actuales
if [[ -f /etc/iptables/rules.v4 ]]; then
    cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.backup.$(date +%Y%m%d_%H%M%S)
    echo "[INFO] Backup de reglas anteriores creado"
fi

# Flush previo
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t raw -F
iptables -t raw -X

# Políticas por defecto
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Permitir loopback (localhost)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Stateful: permitir tráfico establecido/relacionado
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Anti-spoofing: bloquear paquetes falsificados de LAN
iptables -A INPUT -i $IFACE ! -s $LAN -j DROP

# Protección contra paquetes fragmentados
iptables -A INPUT -f -j DROP

# Conectividad Internet
# HTTP/HTTPS saliente
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# DNS solo al router confiable
iptables -A OUTPUT -p udp -d $ROUTER --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -d $ROUTER --dport 53 -j ACCEPT

# NTP
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

# ICMP (ping) - opcional pero útil para diagnóstico
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# Servicios LAN
# Samba cliente → servidor
iptables -A OUTPUT -p tcp -d $SAMBA --dport 139 -j ACCEPT
iptables -A OUTPUT -p tcp -d $SAMBA --dport 445 -j ACCEPT
iptables -A INPUT -p tcp -s $SAMBA --sport 139 -j ACCEPT
iptables -A INPUT -p tcp -s $SAMBA --sport 445 -j ACCEPT

# LocalSend
iptables -A INPUT -p tcp -s $LAN --dport 53317 -j ACCEPT
iptables -A INPUT -p udp -s $LAN --dport 53317 -j ACCEPT

# InputLeap
iptables -A INPUT -p tcp -s $LAN --dport 24800 -j ACCEPT

# SSH LAN only + rate limiting
iptables -A INPUT -p tcp -s $LAN --dport 22 -m conntrack --ctstate NEW \
         -m recent --set --name SSH
iptables -A INPUT -p tcp -s $LAN --dport 22 -m conntrack --ctstate NEW \
         -m recent --update --seconds 60 --hitcount 3 --name SSH -j DROP
iptables -A INPUT -p tcp -s $LAN --dport 22 -j ACCEPT

# mDNS/Avahi
iptables -A INPUT -p udp -s $LAN --dport 5353 -j ACCEPT

# Desarrollo local
# Git (SSH saliente - HTTPS ya está cubierto arriba)
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Hardening adicional
# Bloquear tráfico IPv6 si no se usa
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# Protección contra escaneo de puertos (SYN flood básico)
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Logging antes del DROP final para auditoría (opcional)
iptables -A INPUT -j LOG --log-prefix "[IPTABLES-DROP] "
iptables -A FORWARD -j LOG --log-prefix "[IPTABLES-FWD-DROP] "

# Persistencia
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Verificación
echo ""
echo "=== Reglas de iptables aplicadas ==="
iptables -L -n -v --line-numbers

echo ""
echo "=== Estado del firewall ==="
iptables -L -n -v

echo ""
echo "[INFO] Configuración de firewall completada."
echo "[INFO] Recuerde verificar conectividad antes de salir de esta sesión."