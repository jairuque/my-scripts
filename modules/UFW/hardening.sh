#!/bin/bash
# Firewall restrictivo para Linux Mint 22.3 / Ubuntu 24.04
# Política base: default deny INPUT/FORWARD, allow OUTPUT legítimo

IFACE="enpXsY"
LAN="192.168.1.0/24"
ROUTER="192.168.1.1"
SAMBA="192.168.1.100"

# --- Verificar instalación de iptables-persistent ---
if ! dpkg -l | grep -q iptables-persistent; then
    echo "[INFO] iptables-persistent no está instalado. Instalando..."
    apt-get update && apt-get install -y iptables-persistent
else
    echo "[INFO] iptables-persistent ya está instalado."
fi

# --- Flush previo ---
iptables -F
iptables -X

# --- Políticas por defecto ---
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# --- Permitir loopback (localhost) ---
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# --- Stateful: permitir tráfico establecido/relacionado ---
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# --- Anti-spoofing: bloquear paquetes falsificados de LAN ---
iptables -A INPUT -i $IFACE ! -s $LAN -j DROP

# --- Conectividad Internet ---
# HTTP/HTTPS saliente
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# DNS solo al router confiable
iptables -A OUTPUT -p udp -d $ROUTER --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -d $ROUTER --dport 53 -j ACCEPT

# NTP
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

# --- Servicios LAN ---
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

# --- Desarrollo local ---
# (No se monta LAMP en este equipo, reglas eliminadas)
# Git (HTTPS/SSH saliente)
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# --- Escritorio remoto (bloqueado por defecto) ---
# Para habilitar temporalmente:
# iptables -A INPUT -p tcp --dport 3389 -s $LAN -j ACCEPT   # RDP
# iptables -A INPUT -p tcp --dport 5900 -s $LAN -j ACCEPT   # VNC

# --- Hardening adicional ---
# Bloquear tráfico IPv6 si no se usa
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# Protección contra escaneo de puertos (SYN flood básico)
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# --- Persistencia ---
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# --- Verificación ---
iptables -L -n -v