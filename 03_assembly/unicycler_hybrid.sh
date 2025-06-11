#!/bin/bash
# Unicycler Hybrid Assembly - Versión simplificada

#############################
### CONFIGURACIÓN INICIAL ###
#############################

# Directorios base
ILLUMINA_DIR="data/processed/illumina"
ONT_DIR="data/processed/corrected"
PACBIO_DIR="data/processed/corrected"
OUTPUT_DIR="results/assemblies"
LOG_DIR="logs/assembly"

# Archivos de entrada
ILLUMINA_R1="${ILLUMINA_DIR}/output_R1_paired.fastq"
ILLUMINA_R2="${ILLUMINA_DIR}/output_R2_paired.fastq"
ONT="${ONT_DIR}/ont_trim_504_trim_end_34499_minlen_1000_CORRECTED.fasta"
PACBIO1="${PACBIO_DIR}/pacbio_cola50_trim34499_CORRECTED.1.subreads.fasta"
PACBIO2="${PACBIO_DIR}/pacbio_cola50_trim34499_CORRECTED.2.subreads.fasta"
PACBIO3="${PACBIO_DIR}/pacbio_cola50_trim34499_CORRECTED.3.subreads.fasta"

# Parámetros Unicycler
THREADS=8

###########################
### INICIO DEL PROCESO ###
###########################

# Crear directorios necesarios
mkdir -p ${OUTPUT_DIR} ${LOG_DIR}

# Archivo de log
LOG_FILE="${LOG_DIR}/unicycler_$(date +%Y%m%d).log"
echo "=== INICIO DE ENSAMBLAJES UNICYCLER ===" | tee ${LOG_FILE}
date | tee -a ${LOG_FILE}

########################################
### 1. ENSAMBLAJE COMPLETO (Illumina + ONT + PacBio)
########################################

echo "Ejecutando Unicycler con Illumina + ONT + PacBio..." | tee -a ${LOG_FILE}

unicycler \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    -l ${ONT} \
    -l ${PACBIO1} \
    -l ${PACBIO2} \
    -l ${PACBIO3} \
    -o ${OUTPUT_DIR}/unicycler_full \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Ensamblaje completo terminado. Archivo de salida:" | tee -a ${LOG_FILE}
ls -lh ${OUTPUT_DIR}/unicycler_full/assembly.fasta | tee -a ${LOG_FILE}

########################################
### 2. ENSAMBLAJE HÍBRIDO (Illumina + ONT)
########################################

echo "Ejecutando Unicycler con Illumina + ONT..." | tee -a ${LOG_FILE}

unicycler \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    -l ${ONT} \
    -o ${OUTPUT_DIR}/unicycler_hybrid \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Ensamblaje híbrido terminado. Archivo de salida:" | tee -a ${LOG_FILE}
ls -lh ${OUTPUT_DIR}/unicycler_hybrid/assembly.fasta | tee -a ${LOG_FILE}

########################################
### 3. ENSAMBLJE SOLO ILLUMINA
########################################

echo "Ejecutando Unicycler solo con Illumina..." | tee -a ${LOG_FILE}

unicycler \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    -o ${OUTPUT_DIR}/unicycler_illumina \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Ensamblaje Illumina terminado. Archivo de salida:" | tee -a ${LOG_FILE}
ls -lh ${OUTPUT_DIR}/unicycler_illumina/assembly.fasta | tee -a ${LOG_FILE}

########################################
### 4. COMPARACIÓN CON QUAST (Opcional)
########################################

echo "Generando comparación con QUAST de ensamblajes de Unicycler y SPAdes..." | tee -a ${LOG_FILE}

quast.py \
    ${OUTPUT_DIR}/unicycler_full/assembly.fasta \
    ${OUTPUT_DIR}/unicycler_hybrid/assembly.fasta \
    ${OUTPUT_DIR}/unicycler_illumina/assembly.fasta \
    ${OUTPUT_DIR}/spades_full/contigs.fasta \
    ${OUTPUT_DIR}/spades_hybrid/contigs.fasta \
    ${OUTPUT_DIR}/spades_illumina/contigs.fasta \	
    -o ${OUTPUT_DIR}/quast_comparison 2>> ${LOG_FILE}

########################################
### FINALIZACIÓN
########################################

echo "=== TODOS LOS ENSAMBLAJES COMPLETADOS ===" | tee -a ${LOG_FILE}
echo "Resultados en:" | tee -a ${LOG_FILE}
echo "- Full: ${OUTPUT_DIR}/unicycler_full" | tee -a ${LOG_FILE}
echo "- Hybrid: ${OUTPUT_DIR}/unicycler_hybrid" | tee -a ${LOG_FILE}
echo "- Illumina: ${OUTPUT_DIR}/unicycler_illumina" | tee -a ${LOG_FILE}
echo "- Comparación QUAST: ${OUTPUT_DIR}/quast_comparison" | tee -a ${LOG_FILE}
date | tee -a ${LOG_FILE}