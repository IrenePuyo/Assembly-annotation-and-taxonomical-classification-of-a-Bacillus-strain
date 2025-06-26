#!/bin/bash
# Script para análisis de ortólogos y filogenia multigénica en Bacillus

# 1) Configuración inicial
echo "=== INICIANDO ANÁLISIS DE ORTÓLOGOS Y FILOGENIA ==="
BASE_DIR=$(pwd)
ORTHO_DIR="${BASE_DIR}/Bacillus_homologues"
SINGLE_COPY_DIR="${BASE_DIR}/single-copy"
LOG_FILE="${BASE_DIR}/log_analysis.txt"

# Crear directorios necesarios
mkdir -p "${SINGLE_COPY_DIR}" "${ORTHO_DIR}"

# 2) Identificación de clusters de ortólogos con 1 copia por genoma
echo -e "\n=== EJECUTANDO get_homologues.pl ==="
get_homologues.pl -d "${BASE_DIR}/Bacillus/" -e -M -A -n 6 &> "${LOG_FILE}"

# 3) Preparación de archivos para filogenia
echo -e "\n=== PREPARANDO ARCHIVOS PARA FILOGENIA ==="

# Copiar clusters de copia única
echo "Copiando clusters de copia única a ${SINGLE_COPY_DIR}"
cp "${ORTHO_DIR}/BacillusvelezensisMEP218_f0_alltaxa_algOMCL_e1_"/* "${SINGLE_COPY_DIR}/"

# Cambiar al directorio de trabajo
cd "${SINGLE_COPY_DIR}" || exit

# Modificar nombres de cepas en los archivos
echo "Modificando nombres de cepas en los archivos..."
for f in *.faa; do
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.ori.gbk/|ori|Bacillus_sp_ARP23.ori.gbk/g' "$f"
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.cur.gbk/|cur|Bacillus_sp_ARP23.cur.gbk/g' "$f"
done

for f in *.fna; do
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.ori.gbk/|ori|Bacillus_sp_ARP23.ori.gbk/g' "$f"
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.cur.gbk/|cur|Bacillus_sp_ARP23.cur.gbk/g' "$f"
done

# Eliminar archivos de backup
rm -f *.bak

# 4) Ejecutar análisis filogenético en Docker
echo -e "\n=== EJECUTANDO ANÁLISIS FILOGENÉTICO EN DOCKER ==="
echo "Iniciando contenedor get_phylomarkers..."

# Comando Docker con montaje de volumen
docker_cmd="sudo docker run --rm -it -v '${SINGLE_COPY_DIR}:/home/you/clusters vinuesa/get_phylomarkers /bin/bash -c 'cd clusters && run_get_phylomarkers_pipeline.sh -R 1 -t DNA'"

echo "Ejecutando:"
echo "${docker_cmd}"

# Ejecutar el comando Docker
eval "${docker_cmd}"

# 5) Finalización
echo -e "\n=== ANÁLISIS COMPLETADO ==="
echo "Resultados disponibles en:"
echo "- Ortólogos: ${ORTHO_DIR}"
echo "- Ortólogos de copia única: ${SINGLE_COPY_DIR}"
echo "- Log completo: ${LOG_FILE}"