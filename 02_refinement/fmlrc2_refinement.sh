#!/bin/bash
# Refinement of PacBio and ONT reads using Illumina short reads with FMLRC2

#############################
### INITIAL CONFIGURATION ###
#############################

# Base directories
ILLUMINA_DIR="data/processed/illumina"
PACBIO_DIR="data/processed/pacbio"
ONT_DIR="data/processed/ont"
OUTPUT_DIR="data/processed/corrected"
LOG_DIR="logs/correction"

# Input files
ILLUMINA_R1="${ILLUMINA_DIR}/output_R1_paired.fastq.gz"
ILLUMINA_R2="${ILLUMINA_DIR}/output_R2_paired.fastq.gz"

PACBIO_FILES=(
    "${PACBIO_DIR}/pacbio_cola50_trim34499.1.subreads.fastq"
    "${PACBIO_DIR}/pacbio_cola50_trim34499.2.subreads.fastq"
    "${PACBIO_DIR}/pacbio_cola50_trim34499.3.subreads.fastq"
)

ONT_FILE="${ONT_DIR}/ont_trim_504_trim_end_34499_minlen_1000.fastq"

# FMLRC2 configuration
FMLRC2_PATH="/home/rsancho/software/fmlrc2/target/release/fmlrc2"
INDEX_FILE="${OUTPUT_DIR}/illumina_index.npy"
THREADS=4

###########################
### HELPER FUNCTIONS #####
###########################

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

# File existence check
check_file() {
    if [ ! -f "$1" ]; then
        log "ERROR: File not found: $1"
        exit 1
    fi
}

###########################
### BEGIN PROCESSING #####
###########################

# Create necessary directories
mkdir -p ${OUTPUT_DIR} ${LOG_DIR}

# Log file with timestamp
LOG_FILE="${LOG_DIR}/fmlrc2_correction_$(date +%Y%m%d).log"
log "=== STARTING CORRECTION WITH FMLRC2 ==="

########################################
### STEP 1: Build msbwt2 index #########
########################################

log "1. Building msbwt2 index..."

check_file ${ILLUMINA_R1}
check_file ${ILLUMINA_R2}

msbwt2-build -o ${INDEX_FILE} ${ILLUMINA_R1} ${ILLUMINA_R2} 2>> ${LOG_FILE} || {
    log "ERROR: Failed to build index"
    exit 1
}

########################################
### STEP 2: Correct PacBio reads ######
########################################

log "2. Starting PacBio read correction..."

for pb_file in "${PACBIO_FILES[@]}"; do
    check_file ${pb_file}
    base_name=$(basename ${pb_file} .subreads.fastq)
    output_file="${OUTPUT_DIR}/${base_name}_CORRECTED.subreads.fasta"
    
    log "Processing ${base_name}..."
    ${FMLRC2_PATH} ${INDEX_FILE} ${pb_file} ${output_file} 2>> ${LOG_FILE} || {
        log "ERROR: Correction failed for ${base_name}"
        exit 1
    }
    
    log "${base_name}: Correction completed → ${output_file}"
done

########################################
### STEP 3: Correct ONT reads #########
########################################

log "3. Starting ONT read correction..."

check_file ${ONT_FILE}
ont_output="${OUTPUT_DIR}/ont_trim_504_trim_end_34499_minlen_1000_CORRECTED.fasta"

log "Running in background..."
nohup ${FMLRC2_PATH} ${INDEX_FILE} ${ONT_FILE} ${ont_output} >> ${LOG_FILE} 2>&1 &

log "ONT process running in background (PID $!)"
log "You can monitor with: tail -f ${LOG_FILE}"

########################################
### FINALIZATION ######################
########################################

log "=== CORRECTION SUCCESSFULLY INITIATED ==="
log "Index generated: ${INDEX_FILE}"
log "PacBio results: ${OUTPUT_DIR}/*_CORRECTED.subreads.fasta"
log "ONT result: ${ont_output} (in progress)"
log "Full details in: ${LOG_FILE}"
