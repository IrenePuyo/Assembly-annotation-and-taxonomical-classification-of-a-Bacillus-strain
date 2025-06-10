#!/bin/bash
# pacbio_filter.sh - Preprocesamiento de lecturas PacBio
# Recorte de colas, filtrado por calidad/longitud y verificaciones

#############################
### CONFIGURACIÓN INICIAL ###
#############################

# Directorios
INPUT_DIR="data/raw/pacbio"
OUTPUT_DIR="data/processed/pacbio"
LOG_DIR="logs"
QC_DIR="results/qc/pacbio"

mkdir -p ${OUTPUT_DIR} ${LOG_DIR} ${QC_DIR}

# Archivos de entrada
PACBIO_FILES=(
    "m180704_113818_42146_c101474342550000001823318302141971_s1_p0.1.subreads.fastq"
    "m180704_113818_42146_c101474342550000001823318302141971_s1_p0.2.subreads.fastq"
    "m180704_113818_42146_c101474342550000001823318302141971_s1_p0.3.subreads.fastq"
)

# Parámetros de filtrado (ajustados a prueba y error comparando fastqcs)
MIN_LENGTH=1000          
MIN_QUAL=9               
TRIM_TAIL=50             
TRIM_TO_LENGTH=34499     

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
### PROCESAMIENTO #########
###########################

LOG_FILE="${LOG_DIR}/pacbio_preprocess_$(date +%Y%m%d).log"
log "=== INICIO DE PROCESAMIENTO PACBIO ==="

for file in "${PACBIO_FILES[@]}"; do
    # Definir nombres de archivos
    base_name=$(basename ${file} .fastq)
    input_file="${INPUT_DIR}/${file}"
    output_good="${OUTPUT_DIR}/FILTERED_${base_name}.fastq"
    output_bad="${OUTPUT_DIR}/LOW_QUALITY_${base_name}.fastq"
    trimmed_output="${OUTPUT_DIR}/TRIMMED_FILTERED_${base_name}.fastq"

    # Verificar archivo de entrada
    check_file ${input_file}
    
    ####################################
    ### PASO 1: Filtrado inicial #######
    ####################################
    log "Procesando ${file} - Filtrado inicial..."
    
    prinseq-lite -fastq ${input_file} \
        -out_good ${output_good} \
        -out_bad ${output_bad} \
        -min_len ${MIN_LENGTH} \
        -min_qual_mean ${MIN_QUAL} \
        -trim_tail_right ${TRIM_TAIL} 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR en filtrado inicial de ${file}"
        exit 1
    fi

    ####################################
    ### PASO 2: Trimming a longitud fija
    ####################################
    log "Procesando ${file} - Trimming a ${TRIM_TO_LENGTH}bp..."
    
    prinseq-lite -fastq ${output_good} \
        -trim_to ${TRIM_TO_LENGTH} \
        -out_good ${trimmed_output} \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR en trimming de ${file}"
        exit 1
    fi

    ####################################
    ### PASO 3: Control de calidad ####
    ####################################
    log "Generando reporte de calidad para ${trimmed_output}..."
    
    fastqc -o ${QC_DIR} ${trimmed_output} 2>> ${LOG_FILE}
done

####################################
### PASO 4: Reporte consolidado ####
####################################
log "Generando reporte MultiQC..."

multiqc ${QC_DIR} -o ${QC_DIR} --filename multiqc_report_pacbio 2>> ${LOG_FILE}

log "=== PROCESAMIENTO COMPLETADO ==="
log "Resultados en: ${OUTPUT_DIR}"
log "Reportes de calidad en: ${QC_DIR}"
log "Detalles completos en: ${LOG_FILE}"