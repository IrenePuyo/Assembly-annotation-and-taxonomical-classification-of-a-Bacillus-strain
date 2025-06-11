#!/bin/bash
# SPAdes Hybrid Assembly

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

# Parámetros SPAdes
THREADS=8

###########################
### INICIO DEL PROCESO ###
###########################

# Crear directorios necesarios
mkdir -p ${OUTPUT_DIR} ${LOG_DIR}

# Archivo de log
LOG_FILE="${LOG_DIR}/spades_$(date +%Y%m%d).log"
echo "=== INICIO DE ENSAMBLAJES ===" | tee ${LOG_FILE}
date | tee -a ${LOG_FILE}

########################################
### 1. ENSAMBLAJE COMPLETO (Illumina + ONT + PacBio)
########################################

echo "Ejecutando SPAdes con Illumina + ONT + PacBio..." | tee -a ${LOG_FILE}

spades.py \
    -o ${OUTPUT_DIR}/spades_full \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    --nanopore ${ONT} \
    --pacbio ${PACBIO1} \
    --pacbio ${PACBIO2} \
    --pacbio ${PACBIO3} \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Ensamblaje completo terminado. Contigs:" | tee -a ${LOG_FILE}
grep -c "^>" ${OUTPUT_DIR}/spades_full/contigs.fasta | tee -a ${LOG_FILE}

########################################
### 2. ENSAMBLAJE HÍBRIDO (Illumina + ONT)
########################################

echo "Ejecutando SPAdes con Illumina + ONT..." | tee -a ${LOG_FILE}

spades.py \
    -o ${OUTPUT_DIR}/spades_hybrid \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    --nanopore ${ONT} \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Ensamblaje híbrido terminado. Contigs:" | tee -a ${LOG_FILE}
grep -c "^>" ${OUTPUT_DIR}/spades_hybrid/contigs.fasta | tee -a ${LOG_FILE}

########################################
### 3. ENSAMBLAJE SOLO ILLUMINA
########################################

echo "Ejecutando SPAdes solo con Illumina..." | tee -a ${LOG_FILE}

spades.py \
    -o ${OUTPUT_DIR}/spades_illumina \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    --threads ${THREADS} \
    --isolate 2>> ${LOG_FILE}

echo "Ensamblaje Illumina terminado. Contigs:" | tee -a ${LOG_FILE}
grep -c "^>" ${OUTPUT_DIR}/spades_illumina/contigs.fasta | tee -a ${LOG_FILE}

########################################
### FINALIZACIÓN
########################################

echo "=== TODOS LOS ENSAMBLAJES COMPLETADOS ===" | tee -a ${LOG_FILE}
echo "Resultados en:" | tee -a ${LOG_FILE}
echo "- Full: ${OUTPUT_DIR}/spades_full" | tee -a ${LOG_FILE}
echo "- Hybrid: ${OUTPUT_DIR}/spades_hybrid" | tee -a ${LOG_FILE}
echo "- Illumina: ${OUTPUT_DIR}/spades_illumina" | tee -a ${LOG_FILE}
date | tee -a ${LOG_FILE}