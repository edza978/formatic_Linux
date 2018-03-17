#!/bin/bash
# Ubicancion vboxmanage
VBM=$(which vboxmanage)
# Listado de VMs
VMS=$(${VBM} list vms | tr -d \"| awk '{print $1}')
# Cantidad cores
PROC=$(cat /proc/cpuinfo | grep processor | wc -l)
# Cantidad Threads por Core
PROCPUCORE=$(cat /proc/cpuinfo | grep "cpu cores" | awk '{print $4}' | tail -1)
# Mitad Cores
PROCH=$(echo $(( PROC * PROCPUCORE / 2 )))
# Total de RAM
MEM=$(free -m | grep -v total | grep -iv swap | awk '{print $2}')
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

function creaMenu()
{
 # Titulo menu
 Title=$1; shift
 # Iniciar menu
 MEN="dialog --backtitle \"${Title}\" --menu \"${Title}\" 0 0 0"
 # Optener opciones menu
 while [ ! -z "$1" ]; do
  OP=$(echo $1 | awk '{print $1}');
  NOM=$(echo $1 | awk '{print $2}');
  shift;
  MEN="${MEN} ${OP} ${NOM}";
 done
 # Finalizar menu
 MEN="${MEN} 2> ${OUT}"
 # Retornar MENU.
 echo ${MEN}
}

## Menu inicial
MENU=$(creaMenu "Seleccione tarea" "1 Crear" "2 Listar" "3 Modificar" "4 Eliminar");eval ${MENU};OPC=$(cat ${OUT})
if [ ${OPC} -eq 1 ]; then
 # Solicitar nombre VM
 dialog --inputbox "Nombre de la VM: " 8 30 2> ${OUT}
 # Obtener nombre digitado
 NAME=$(cat ${OUT})
 # Verificar que el nomnbre no esta.
 grep -q  ${NAME} <<< ${VMS}
 RET=$(echo $?)
 # Verificar si el nombre esta repetido
 if [ ${RET} -eq 0 ]; then
  dialog --title 'ERROR' --msgbox 'Ese nombre ya esta asignado.' 5 40
  exec bash $0
 # Verificar si se ingreso nombre
 elif [ -z ${NAME} ]; then
  dialog --title 'ERROR' --msgbox 'Debe ingresar un nombre.' 5 40
  exec bash $0
 fi

 ## Menu Linux
 # Obtener todos los Linux
 OSLNX=$(${VBM} list ostypes | tr -s ' ' | grep -B 2 "Family ID: Linux"| grep ID |grep -v Family | awk '{print $2}')
 # Ajustar alto del menu
 MENU="dialog --menu \"Seleccione Linux a instalar: \" 0 0 0"
 for i in ${OSLNX}; do MENU="${MENU} ${i} ${i}"; done
 MENU="${MENU} 2> ${OUT}"; eval ${MENU}; OSID=$(cat ${OUT})

 ## Menu Cores
 MENU="dialog --menu \"Seleccione cantidad de Cores: \" 0 0 0"
 for((i=1;i<=${PROCH};++i)); do MENU="${MENU} ${i} ${i}"; done
 MENU="${MENU} 2> ${OUT}"; eval ${MENU}; COR=$(cat ${OUT})

 ## Menu porcentaje CPU a usar
 MENU="dialog --menu \"Seleccione porcentaje maximo de CPU a usar: \" 0 0 0"
 for i in $(seq 10 10 80); do MENU="${MENU} ${i} ${i}"; done
 MENU="${MENU} 2> ${OUT}"; eval ${MENU}; PCPU=$(cat ${OUT})

 ## Menu tamaño disco
 MENU="dialog --menu \"Seleccione el tamaño de Disco duro: \" 0 0 0"
 for i in 500 2048 4096 8192; do MENU="${MENU} ${i} ${i}"; done
 MENU="${MENU} 2> ${OUT}"; eval ${MENU}; DSK=$(cat ${OUT})
 
 ## Menu tamaño disco
 MENU="dialog --menu \"Seleccione el porcentaje de RAM: \" 0 0 0"
 for i in 10 25 50 75; do MENU="${MENU} ${i} ${i}%"; done
 MENU="${MENU} 2> ${OUT}"; eval ${MENU}; RAM=$(cat ${OUT})
 # Calcular porcentaje RAM a asignar
 VMRAM=$((MEM * RAM / 100))

 rm -f ${OUT}
 echo "${VMS} ${NAME} ${OSID} ${COR} ${PCPU} ${DSK} ${RAM} ${VMRAM}"

 echo "** Creando la VM ${NAME} con SO ${OSID}"
 ${VBM} createvm --name ${NAME} --ostype ${OSID} --register

 echo "** Asignando ${COR} CPUs a ${NAME}"
 ${VBM} modifyvm ${NAME} --cpus ${COR}

 echo "** Asignando restriccion de ${PCPU}% a ${NAME}"
 ${VBM} modifyvm ${NAME} --cpuexecutioncap ${PCPU}

 echo "** Asignando ${VMRAM}MB de RAM a ${NAME}"
 ${VBM} modifyvm ${NAME} --memory ${VMRAM}

 echo "** Creando disco ${NAME}.vdi de ${DSK}MBs"
 ${VBM} createmedium disk --filename ${HOME}/VirtualBox\ VMs/${NAME}/${NAME}.vdi --size ${DSK} --format VDI

 echo "** Anexando controlador SATA a la VM ${NAME}"
 ${VBM} storagectl ${NAME} --name "SATA Controller" --add sata --controller IntelAHCI

 echo "** Anexando ${NAME}.vdi a la VM ${NAME}"
 ${VBM} storageattach ${NAME} --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ${HOME}/VirtualBox\ VMs/${NAME}/${NAME}.vdi

elif [ ${OPC} -eq 2 ]; then
 dialog --title "VMs Existentes" --msgbox "${VMS}" 10 30
elif [ ${OPC} -eq 3 ]; then
 echo "Modificar"
else 
 echo "Eliminar"
fi
rm -f ${OUT}

