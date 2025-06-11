#!/bin/bash
# Refinamiento de lecturas de PacBio y ONT con lecturas cortas de Illumina con FMLRC2

#############################
### CONFIGURACIÓN INICIAL ###
#############################

# Directorios base
ILLUMINA_DIR="data/processed/illumina"
PACBIO_DIR="data/processed/pacbio"
ONT_DIR="data/processed/ont"
OUTPUT_DIR="data/processed/corrected"
LOG_DIR="logs/correction"

# Archivos de entrada
ILLUMINA_R1="${ILLUMINA_DIR}/output_R1_paired.fastq.gz"
ILLUMINA_R2="${ILLUMINA_DIR}/output_R2_paired.fastq.gz"

PACBIO_FILES=(
    "${PACBIO_DIR}/pacbio_cola50_trim34499.1.subreads.fastq"
    "${PACBIO_DIR}/pacbio_cola50_trim34499.2.subreads.fastq"
    "${PACBIO_DIR}/pacbio_cola50_trim34499.3.subreads.fastq"
)

ONT_FILE="${ONT_DIR}/ont_trim_504_trim_end_34499_minlen_1000.fastq"

# Configuración FMLRC2
FMLRC2_PATH="/home/rsancho/software/fmlrc2/target/release/fmlrc2"
INDEX_FILE="${OUTPUT_DIR}/illumina_index.npy"
THREADS=4

###########################
### FUNCIONES DE CONTROL ##
###########################

# Función para registro de logs
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

# Función para verificar archivos
check_file() {
    if [ ! -f "$1" ]; then
        log "ERROR: Archivo no encontrado: $1"
        exit 1
    fi
}

###########################
### INICIO DEL PROCESO ###
###########################

# Crear directorios necesarios
mkdir -p ${OUTPUT_DIR} ${LOG_DIR}

# Archivo de log con fecha
LOG_FILE="${LOG_DIR}/fmlrc2_correction_$(date +%Y%m%d).log"
log "=== INICIO DE CORRECCIÓN CON FMLRC2 ==="

########################################
### PASO 1: Construcción del índice ####
########################################

log "1. Construyendo índice msbwt2..."

check_file ${ILLUMINA_R1}
check_file ${ILLUMINA_R2}

msbwt2-build -o ${INDEX_FILE} ${ILLUMINA_R1} ${ILLUMINA_R2} 2>> ${LOG_FILE} || {
    log "ERROR en construcción del índice"
    exit 1
}

########################################
### PASO 2: Corrección de PacBio #######
########################################

log "2. Iniciando corrección de archivos PacBio..."

for pb_file in "${PACBIO_FILES[@]}"; do
    check_file ${pb_file}
    base_name=$(basename ${pb_file} .subreads.fastq)
    output_file="${OUTPUT_DIR}/${base_name}_CORRECTED.subreads.fasta"
    
    log "Procesando ${base_name}..."
    ${FMLRC2_PATH} ${INDEX_FILE} ${pb_file} ${output_file} 2>> ${LOG_FILE} || {
        log "ERROR en corrección de ${base_name}"
        exit 1
    }
    
    log "${base_name}: Corrección completada → ${output_file}"
done

########################################
### PASO 3: Corrección de ONT ########
########################################

log "3. Iniciando corrección de archivo ONT..."

check_file ${ONT_FILE}
ont_output="${OUTPUT_DIR}/ont_trim_504_trim_end_34499_minlen_1000_CORRECTED.fasta"

log "Ejecutando en segundo plano..."
nohup ${FMLRC2_PATH} ${INDEX_FILE} ${ONT_FILE} ${ont_output} >> ${LOG_FILE} 2>&1 &

log "Proceso ONT corriendo en segundo plano (PID $!)"
log "Puedes monitorear con: tail -f ${LOG_FILE}"

########################################
### FINALIZACIÓN ######################
########################################

log "=== CORRECCIÓN INICIADA CON ÉXITO ==="
log "Índice generado: ${INDEX_FILE}"
log "Resultados PacBio: ${OUTPUT_DIR}/*_CORRECTED.subreads.fasta"
log "Resultado ONT: ${ont_output} (en progreso)"
log "Detalles completos en: ${LOG_FILE}"