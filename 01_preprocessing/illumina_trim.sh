#!/bin/bash
# illumina_trim.sh - Preprocesamiento de lecturas Illumina
# Cutadapt + Trimmomatic + Control de calidad

#############################
### 1. CONFIGURACIÓN #######
#############################

# Directorios
INPUT_DIR="data/raw/illumina"
OUTPUT_DIR="data/processed/trimmed"
QC_DIR="results/qc"
LOG_DIR="logs"
mkdir -p ${OUTPUT_DIR} ${QC_DIR} ${LOG_DIR}

# Archivos de entrada
R1_IN="${INPUT_DIR}/diverse-ARP23_S33_L001_R1_001.fastq"
R2_IN="${INPUT_DIR}/diverse-ARP23_S33_L001_R2_001.fastq"

# Archivos intermedios (Cutadapt)
R1_CUTADAPT="${OUTPUT_DIR}/intermediate_R1_cutadapt.fastq"
R2_CUTADAPT="${OUTPUT_DIR}/intermediate_R2_cutadapt.fastq"

# Archivos finales (Trimmomatic)
R1_OUT="${OUTPUT_DIR}/final_R1_trimmed.fastq"
R2_OUT="${OUTPUT_DIR}/final_R2_trimmed.fastq"
UNPAIRED_R1="${OUTPUT_DIR}/unpaired_R1.fastq"
UNPAIRED_R2="${OUTPUT_DIR}/unpaired_R2.fastq"

# Configuración de Trimmomatic
TRIM_PARAMS="HEADCROP:15 MINLEN:50 AVGQUAL:28"

# Sistema de logging (registro)
LOG_FILE="${LOG_DIR}/illumina_processing_$(date +%Y%m%d).log"
exec > >(tee -a ${LOG_FILE}) 2>&1

#############################
### 2. FUNCIONES ###########
#############################

# Función para verificar archivos de entrada
check_files() {
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            echo "ERROR: Archivo no encontrado: $file" | tee -a ${LOG_FILE}
            exit 1
        fi
    done
}

#############################
### 3. PROCESAMIENTO #######
#############################

echo "=== INICIO DE PROCESAMIENTO ===" | tee -a ${LOG_FILE}
date | tee -a ${LOG_FILE}

### 3.1 Cutadapt (eliminación de adaptadores)
echo "[CUTADAPT] Eliminando adaptadores..." | tee -a ${LOG_FILE}

cutadapt -a "CTGTCTCTTATACACATCTCCGAGCCCACGAGAC" \
         -A "CTGTCTCTTATACACATCTGACGCTGCCGACGA" \
         -o ${R1_CUTADAPT} \
         -p ${R2_CUTADAPT} \
         ${R1_IN} \
         ${R2_IN} || { echo "Error en Cutadapt"; exit 1; }

### 3.2 Trimmomatic (filtrado de calidad)
echo "[TRIMMOMATIC] Filtrado por calidad..." | tee -a ${LOG_FILE}

trimmomatic PE -phred33 \
               ${R1_CUTADAPT} ${R2_CUTADAPT} \
               ${R1_OUT} ${UNPAIRED_R1} \
               ${R2_OUT} ${UNPAIRED_R2} \
               ${TRIM_PARAMS} || { echo "Error en Trimmomatic"; exit 1; }

### 3.3 Control de calidad post-trimming
echo "[FASTQC] Analizando calidad final..." | tee -a ${LOG_FILE}
fastqc -o ${QC_DIR} ${R1_OUT} ${R2_OUT}

### 3.4 Reporte consolidado
echo "[MULTIQC] Generando reporte global..." | tee -a ${LOG_FILE}
multiqc ${QC_DIR} -o ${QC_DIR} --filename multiqc_report_final

#############################
### 4. FINALIZACIÓN #######
#############################

echo "Proceso completado correctamente" | tee -a ${LOG_FILE}
echo "Archivos finales en: ${OUTPUT_DIR}" | tee -a ${LOG_FILE}
echo "Reportes de calidad en: ${QC_DIR}" | tee -a ${LOG_FILE}
echo "=== FIN DEL PROCESO ===" | tee -a ${LOG_FILE}
date | tee -a ${LOG_FILE}