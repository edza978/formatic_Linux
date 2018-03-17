#!/bin/bash
# Ubicancion vboxmanage
VBM=$(which vboxmanage)
# Listado de VMs
VMS=$(${VBM} list vms | tr -d \"| awk '{print $1}')
# Cantidad cores
PROC=$(cat /proc/cpuinfo | grep processor | wc -l)
# Mitad Cores
PROCH=$(echo $(( PROC * 10 / 20 )))
# Archivo de salida
OUT=$(mktemp)

# Nombre para VM
NAME=""
# OS seleccionado
OSID=""
# Cores seleccionados
COR=0
# % CPU
PCPU=0
# Tamaño Disco
DSK=0

# Menu Inicial
dialog --menu "Seleccione tarea: " 20 40 4 1 Crear 2 Listar 3 Modificar 4 Eliminar 2> ${OUT}
OPC=$(cat ${OUT})
if [ ${OPC} -eq 1 ]; then
 # Solicitar nombre VM
 dialog --inputbox "Nombre de la VM: " 8 30 2> ${OUT}
 # Obtener nombre digitado
 NAME=$(cat ${OUT})
 # Verificar que el nomnbre no esta.
 grep -q  ${NAME} <<< ${VMS}
 RET=$(echo $?)
 if [ ${RET} -eq 0 ]; then
  dialog --title 'ERROR' --msgbox 'Ese nombre ya esta asignado.' 5 40
  bash $0
 fi
 # Mostrar Linux a instalar
 dialog --menu "Seleccione Linux a instalar: " 14 40 6 1 Debian32 2 Debian64 3 RedHat32 4 RedHat64 5 Ubuntu32 6 Ubuntu64 2> ${OUT}
 OPC=$(cat ${OUT})
 # Asignar ID
 case $OPC in
  1) OSID=Debian
  ;;
  2) OSID=Debian_64
  ;;
  3) OSID=RedHat
  ;;
  4) OSID=RedHat_64
  ;;
  5) OSID=Ubuntu
  ;;
  6) OSID=Ubuntu_64
  ;;
 esac
 # Menu Cores
 MENUPROC="dialog --menu \"Seleccione cantidad de Cores: \" 14 40 ${PROCH}"
 for((i=1;i<=${PROCH};++i)); do MENUPROC="${MENUPROC} ${i} ${i}"; done
 MENUPROC="${MENUPROC} 2> ${OUT}"
 eval ${MENUPROC}
 COR=$(cat ${OUT})
 # Menu porcentaje CPU a usar
 MENUCPU="dialog --menu \"Seleccione porcentaje maximo de CPU a usar: \" 14 40 6"
 for i in $(seq 10 10 60); do MENUCPU="${MENUCPU} ${i} ${i}"; done
 MENUCPU="${MENUCPU} 2> ${OUT}"
 eval ${MENUCPU}
 PCPU=$(cat ${OUT})
 # Menu tamaño disco
 MENUDSK="dialog --menu \"Seleccione el tamaño de Disco duro: \" 14 40 4"
 for i in 500 2048 4096 8192; do MENUDSK="${MENUDSK} ${i} ${i}"; done
 MENUDSK="${MENUDSK} 2> ${OUT}"
 eval ${MENUDSK}
 DSK=$(cat ${OUT})
 
elif [ ${OPC} -eq 2 ]; then
 dialog --title "VMs Existentes" --msgbox "${VMS}" 10 30
elif [ ${OPC} -eq 3 ]; then
 echo "Modificar"
else 
 echo "Eliminar"
fi
rm -f ${OUT}
echo "${VMS} ${NAME} ${OSID} ${COR} ${PCPU} ${DSK}"
