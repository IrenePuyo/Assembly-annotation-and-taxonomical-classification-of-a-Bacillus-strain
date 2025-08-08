#!/bin/bash
# SPAdes Hybrid Assembly

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

# SPAdes parameters
THREADS=8

###########################
### BEGIN PROCESSING #####
###########################

# Create necessary directories
mkdir -p ${OUTPUT_DIR} ${LOG_DIR}

# Log file
LOG_FILE="${LOG_DIR}/spades_$(date +%Y%m%d).log"
echo "=== STARTING ASSEMBLIES ===" | tee ${LOG_FILE}
date | tee -a ${LOG_FILE}

########################################
### 1. FULL ASSEMBLY (Illumina + ONT + PacBio)
########################################

echo "Running SPAdes with Illumina + ONT + PacBio..." | tee -a ${LOG_FILE}

spades.py \
    -o ${OUTPUT_DIR}/spades_full \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    --nanopore ${ONT} \
    --pacbio ${PACBIO1} \
    --pacbio ${PACBIO2} \
    --pacbio ${PACBIO3} \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Full assembly finished. Number of contigs:" | tee -a ${LOG_FILE}
grep -c "^>" ${OUTPUT_DIR}/spades_full/contigs.fasta | tee -a ${LOG_FILE}

########################################
### 2. HYBRID ASSEMBLY (Illumina + ONT)
########################################

echo "Running SPAdes with Illumina + ONT..." | tee -a ${LOG_FILE}

spades.py \
    -o ${OUTPUT_DIR}/spades_hybrid \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    --nanopore ${ONT} \
    --threads ${THREADS} 2>> ${LOG_FILE}

echo "Hybrid assembly finished. Number of contigs:" | tee -a ${LOG_FILE}
grep -c "^>" ${OUTPUT_DIR}/spades_hybrid/contigs.fasta | tee -a ${LOG_FILE}

########################################
### 3. ILLUMINA-ONLY ASSEMBLY
########################################

echo "Running SPAdes with Illumina only..." | tee -a ${LOG_FILE}

spades.py \
    -o ${OUTPUT_DIR}/spades_illumina \
    -1 ${ILLUMINA_R1} \
    -2 ${ILLUMINA_R2} \
    --threads ${THREADS} \
    --isolate 2>> ${LOG_FILE}

echo "Illumina-only assembly finished. Number of contigs:" | tee -a ${LOG_FILE}
grep -c "^>" ${OUTPUT_DIR}/spades_illumina/contigs.fasta | tee -a ${LOG_FILE}

########################################
### FINALIZATION
########################################

echo "=== ALL ASSEMBLIES COMPLETED ===" | tee -a ${LOG_FILE}
echo "Results stored in:" | tee -a ${LOG_FILE}
echo "- Full: ${OUTPUT_DIR}/spades_full" | tee -a ${LOG_FILE}
echo "- Hybrid: ${OUTPUT_DIR}/spades_hybrid" | tee -a ${LOG_FILE}
echo "- Illumina: ${OUTPUT_DIR}/spades_illumina" | tee -a ${LOG_FILE}
date | tee -a ${LOG_FILE}
