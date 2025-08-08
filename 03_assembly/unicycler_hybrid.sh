#!/bin/bash
# Unicycler Hybrid Assembly

#############################
### INITIAL CONFIGURATION ###
#############################

# Base directories
ILLUMINA_DIR="data/processed/illumina"
ONT_DIR="data/processed/corrected"
PACBIO_DIR="data/processed/corrected"
OUTPUT_DIR="results/assemblies"
LOG_DIR="logs/assembly"

# Input files
ILLUMINA_R1="${ILLUMINA_DIR}/output_R1_paired.fastq"
ILLUMINA_R2="${ILLUMINA_DIR}/output_R2_paired.fastq"
ONT="${ONT_DIR}/ont_trim_504_trim_end_34499_minlen_1000_CORRECTED.fasta"
PACBIO1="${PACBIO_DIR}/pacbio_cola50_trim34499_CORRECTED.1.subreads.fasta"
PACBIO2="${PACBIO_DIR}/pacbio_cola50_trim34499_CORRECTED.2.subreads.fasta"
PACBIO3="${PACBIO_DIR}/pacbio_cola50_trim34499_CORRECTED.3.subreads.fasta"

# Unicycler parameters
THREADS=8

###########################
### BEGIN PROCESSING #####
###########################

# Create necessary directories
mkdir -p ${OUTPUT_DIR} ${LOG_DIR}

# Log file
LOG_FILE="${LOG_DIR}/unicycler_$(date +%Y%m%d).log"
echo "=== STARTING UNICYCLER ASSEMBLIES ===" | tee ${LOG_FILE}
date | tee -a ${LOG_FILE}

########################################
### 1. FULL ASSEMBLY (Illumina + ONT + PacBio)
########################################

echo "Running Unicycler with Illumina + ONT + PacBio..." | tee -a ${LOG_FILE}

unicycler \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    -l ${ONT} \
    -l ${PACBIO1} \
    -l ${PACBIO2} \
    -l ${PACBIO3} \
    -o ${OUTPUT_DIR}/unicycler_full \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Full assembly completed. Output file:" | tee -a ${LOG_FILE}
ls -lh ${OUTPUT_DIR}/unicycler_full/assembly.fasta | tee -a ${LOG_FILE}

########################################
### 2. HYBRID ASSEMBLY (Illumina + ONT)
########################################

echo "Running Unicycler with Illumina + ONT..." | tee -a ${LOG_FILE}

unicycler \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    -l ${ONT} \
    -o ${OUTPUT_DIR}/unicycler_hybrid \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Hybrid assembly completed. Output file:" | tee -a ${LOG_FILE}
ls -lh ${OUTPUT_DIR}/unicycler_hybrid/assembly.fasta | tee -a ${LOG_FILE}

########################################
### 3. ILLUMINA-ONLY ASSEMBLY
########################################

echo "Running Unicycler with Illumina only..." | tee -a ${LOG_FILE}

unicycler \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    -o ${OUTPUT_DIR}/unicycler_illumina \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Illumina-only assembly completed. Output file:" | tee -a ${LOG_FILE}
ls -lh ${OUTPUT_DIR}/unicycler_illumina/assembly.fasta | tee -a ${LOG_FILE}

########################################
### 4. COMPARISON WITH QUAST (Optional)
########################################

echo "Running QUAST comparison for Unicycler and SPAdes assemblies..." | tee -a ${LOG_FILE}

quast.py \
    ${OUTPUT_DIR}/unicycler_full/assembly.fasta \
    ${OUTPUT_DIR}/unicycler_hybrid/assembly.fasta \
    ${OUTPUT_DIR}/unicycler_illumina/assembly.fasta \
    ${OUTPUT_DIR}/spades_full/contigs.fasta \
    ${OUTPUT_DIR}/spades_hybrid/contigs.fasta \
    ${OUTPUT_DIR}/spades_illumina/contigs.fasta \
    -o ${OUTPUT_DIR}/quast_comparison 2>> ${LOG_FILE}

########################################
### FINALIZATION
########################################

echo "=== ALL ASSEMBLIES COMPLETED ===" | tee -a ${LOG_FILE}
echo "Results available at:" | tee -a ${LOG_FILE}
echo "- Full: ${OUTPUT_DIR}/unicycler_full" | tee -a ${LOG_FILE}
echo "- Hybrid: ${OUTPUT_DIR}/unicycler_hybrid" | tee -a ${LOG_FILE}
echo "- Illumina: ${OUTPUT_DIR}/unicycler_illumina" | tee -a ${LOG_FILE}
echo "- QUAST comparison: ${OUTPUT_DIR}/quast_comparison" | tee -a ${LOG_FILE}
date | tee -a ${LOG_FILE}
