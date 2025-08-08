#!/bin/bash
# ont_trim.sh - Preprocessing of Oxford Nanopore reads
# Includes: Low-quality base trimming, quality/length filtering, and checks

#############################
### INITIAL CONFIGURATION ###
#############################

# Directories
INPUT_DIR="data/raw/ont"
OUTPUT_DIR="data/processed/ont"
LOG_DIR="logs"
QC_DIR="results/qc/ont"

mkdir -p ${OUTPUT_DIR} ${LOG_DIR} ${QC_DIR}

# Input files
ONT_FILES=(
    "3_bacillusX23ori.fastq"       # Original file
    "6_bacillusX23_filtrado.fastq" # Pre-filtered file
)

# Filtering parameters (optimized by trial and error comparing FastQC reports)
TRIM_LEFT=504            
MIN_LENGTH=1000          
MIN_QUAL=20              
TRIM_TO_LENGTH=34499     

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
### PROCESSING PIPELINE ###
###########################

LOG_FILE="${LOG_DIR}/ont_preprocess_$(date +%Y%m%d).log"
log "=== STARTING ONT PREPROCESSING ==="

for file in "${ONT_FILES[@]}"; do
    # Define file names
    base_name=$(basename ${file} .fastq)
    input_file="${INPUT_DIR}/${file}"
    trimmed_output="${OUTPUT_DIR}/${base_name}_trim${TRIM_LEFT}.fastq"
    final_output="${OUTPUT_DIR}/${base_name}_final.fastq"

    # Check input file
    check_file ${input_file}
    
    ####################################
    ### STEP 1: Initial trimming #######
    ####################################
    log "Processing ${file} - Trimming from position ${TRIM_LEFT}..."
    
    prinseq-lite -fastq ${input_file} \
        -trim_left ${TRIM_LEFT} \
        -min_qual_mean ${MIN_QUAL} \
        -out_good "${OUTPUT_DIR}/intermediate_${base_name}" \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR during initial trimming of ${file}"
        exit 1
    fi

    ##########################################
    ### STEP 2: Minimum length filtering #####
    ##########################################
    log "Filtering ${file} by minimum length ${MIN_LENGTH}bp..."
    
    prinseq-lite -fastq "${OUTPUT_DIR}/intermediate_${base_name}.fastq" \
        -min_len ${MIN_LENGTH} \
        -out_good ${trimmed_output} \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR during length filtering of ${file}"
        exit 1
    fi

    ####################################
    ### STEP 3: Fixed-length trimming ##
    ####################################
    log "Trimming ${file} to fixed length ${TRIM_TO_LENGTH}bp..."
    
    prinseq-lite -fastq ${trimmed_output} \
        -trim_to ${TRIM_TO_LENGTH} \
        -out_good ${final_output} \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR during final trimming of ${file}"
        exit 1
    fi

    ####################################
    ### STEP 4: Quality Control ########
    ####################################
    log "Generating quality report for ${final_output}..."
    
    fastqc -o ${QC_DIR} ${final_output} 2>> ${LOG_FILE}

    # Clean up intermediate files
    rm "${OUTPUT_DIR}/intermediate_${base_name}.fastq"
done

####################################
### STEP 5: Consolidated report ####
####################################
log "Generating MultiQC report..."

multiqc ${QC_DIR} -o ${QC_DIR} --filename multiqc_report_ont 2>> ${LOG_FILE}

log "=== PROCESSING COMPLETED ==="
log "Final results in: ${OUTPUT_DIR}"
log "Quality reports in: ${QC_DIR}"
log "Full details in: ${LOG_FILE}"
