#!/bin/bash
clear
echo -e "\e[1;34m--- SALUD: LENOVO FLEX 3 (i7-6500U) ---\e[0m"
echo -e "\e[1;32m[ CPU & TEMPERATURA ]\e[0m"
sensors | grep -E 'Package id 0|Core 0|Core 1'
uptime | awk '{print "Carga sistema: " $10 $11 $12}'

echo -e "\n\e[1;32m[ GPU STATUS ]\e[0m"
if command -v nvidia-smi &> /dev/null; then
    # Si da error es que la NVIDIA está apagada (¡Bien!)
    nvidia-smi 2>&1 | grep -q "failed" && echo "NVIDIA: Apagada (Modo Ahorro)" || echo "NVIDIA: Activa (Generando Calor)"
else
    echo "Driver NVIDIA no detectado."
fi

echo -e "\n\e[1;32m[ MEMORIA RAM ]\e[0m"
free -h | grep -E 'Mem|Swap'

echo -e "\n\e[1;32m[ ESTADO zRAM ]\e[0m"
zramctl
echo -e "\e[1;34m---------------------------------------\e[0m"