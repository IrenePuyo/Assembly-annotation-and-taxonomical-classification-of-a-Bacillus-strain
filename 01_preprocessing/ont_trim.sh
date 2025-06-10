#!/bin/bash
# ont_trim.sh - Preprocesamiento de lecturas Oxford Nanopore
# Incluye: Recorte de bases de peor calidad, filtrado por calidad/longitud y verificaciones

#############################
### CONFIGURACIÓN INICIAL ###
#############################

# Directorios
INPUT_DIR="data/raw/ont"
OUTPUT_DIR="data/processed/ont"
LOG_DIR="logs"
QC_DIR="results/qc/ont"

mkdir -p ${OUTPUT_DIR} ${LOG_DIR} ${QC_DIR}

# Archivos de entrada
ONT_FILES=(
    "3_bacillusX23ori.fastq"      # Archivo original
    "6_bacillusX23_filtrado.fastq" # Archivo pre-filtrado
)

# Parámetros de filtrado (optimizados a prueba y error comparando fastqc)
TRIM_LEFT=504            
MIN_LENGTH=1000          
MIN_QUAL=20              
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

LOG_FILE="${LOG_DIR}/ont_preprocess_$(date +%Y%m%d).log"
log "=== INICIO DE PROCESAMIENTO ONT ==="

for file in "${ONT_FILES[@]}"; do
    # Definir nombres de archivos
    base_name=$(basename ${file} .fastq)
    input_file="${INPUT_DIR}/${file}"
    trimmed_output="${OUTPUT_DIR}/${base_name}_trim${TRIM_LEFT}.fastq"
    final_output="${OUTPUT_DIR}/${base_name}_final.fastq"

    # Verificar archivo de entrada
    check_file ${input_file}
    
    ####################################
    ### PASO 1: Recorte inicial ########
    ####################################
    log "Procesando ${file} - Recorte desde posición ${TRIM_LEFT}..."
    
    prinseq-lite -fastq ${input_file} \
        -trim_left ${TRIM_LEFT} \
        -min_qual_mean ${MIN_QUAL} \
        -out_good "${OUTPUT_DIR}/intermediate_${base_name}" \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR en recorte de ${file}"
        exit 1
    fi

    ####################################
    ### PASO 2: Filtrado por longitud ##
    ####################################
    log "Filtrando ${file} por longitud mínima ${MIN_LENGTH}bp..."
    
    prinseq-lite -fastq "${OUTPUT_DIR}/intermediate_${base_name}.fastq" \
        -min_len ${MIN_LENGTH} \
        -out_good ${trimmed_output} \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR en filtrado de longitud de ${file}"
        exit 1
    fi

    ####################################
    ### PASO 3: Recorte a longitud fija
    ####################################
    log "Recortando ${file} a ${TRIM_TO_LENGTH}bp..."
    
    prinseq-lite -fastq ${trimmed_output} \
        -trim_to ${TRIM_TO_LENGTH} \
        -out_good ${final_output} \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR en recorte final de ${file}"
        exit 1
    fi

    ####################################
    ### PASO 4: Control de calidad ####
    ####################################
    log "Generando reporte de calidad para ${final_output}..."
    
    fastqc -o ${QC_DIR} ${final_output} 2>> ${LOG_FILE}

    # Limpieza de archivos intermedios
    rm "${OUTPUT_DIR}/intermediate_${base_name}.fastq"
done

####################################
### PASO 5: Reporte consolidado ####
####################################
log "Generando reporte MultiQC..."

multiqc ${QC_DIR} -o ${QC_DIR} --filename multiqc_report_ont 2>> ${LOG_FILE}

log "=== PROCESAMIENTO COMPLETADO ==="
log "Resultados finales en: ${OUTPUT_DIR}"
log "Reportes de calidad en: ${QC_DIR}"
log "Detalles completos en: ${LOG_FILE}"