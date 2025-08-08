#!/bin/bash
# pacbio_filter.sh - Preprocessing of PacBio reads
# Tail trimming, quality/length filtering, and validation steps

#############################
### INITIAL CONFIGURATION ###
#############################

# Directories
INPUT_DIR="data/raw/pacbio"
OUTPUT_DIR="data/processed/pacbio"
LOG_DIR="logs"
QC_DIR="results/qc/pacbio"

mkdir -p ${OUTPUT_DIR} ${LOG_DIR} ${QC_DIR}

# Input files
PACBIO_FILES=(
    "m180704_113818_42146_c101474342550000001823318302141971_s1_p0.1.subreads.fastq"
    "m180704_113818_42146_c101474342550000001823318302141971_s1_p0.2.subreads.fastq"
    "m180704_113818_42146_c101474342550000001823318302141971_s1_p0.3.subreads.fastq"
)

# Filtering parameters (tuned by trial and error using FastQC comparisons)
MIN_LENGTH=1000          
MIN_QUAL=9               
TRIM_TAIL=50             
TRIM_TO_LENGTH=34499     

###########################
### HELPER FUNCTIONS #####
###########################

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

# Check file existence
check_file() {
    if [ ! -f "$1" ]; then
        log "ERROR: File not found: $1"
        exit 1
    fi
}

###########################
### PROCESSING PIPELINE ###
###########################

LOG_FILE="${LOG_DIR}/pacbio_preprocess_$(date +%Y%m%d).log"
log "=== STARTING PACBIO PROCESSING ==="

for file in "${PACBIO_FILES[@]}"; do
    # Define file names
    base_name=$(basename ${file} .fastq)
    input_file="${INPUT_DIR}/${file}"
    output_good="${OUTPUT_DIR}/FILTERED_${base_name}.fastq"
    output_bad="${OUTPUT_DIR}/LOW_QUALITY_${base_name}.fastq"
    trimmed_output="${OUTPUT_DIR}/TRIMMED_FILTERED_${base_name}.fastq"

    # Check input file
    check_file ${input_file}
    
    ####################################
    ### STEP 1: Initial filtering ######
    ####################################
    log "Processing ${file} - Initial filtering..."
    
    prinseq-lite -fastq ${input_file} \
        -out_good ${output_good} \
        -out_bad ${output_bad} \
        -min_len ${MIN_LENGTH} \
        -min_qual_mean ${MIN_QUAL} \
        -trim_tail_right ${TRIM_TAIL} 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR during initial filtering of ${file}"
        exit 1
    fi

    ##########################################
    ### STEP 2: Fixed-length trimming ########
    ##########################################
    log "Processing ${file} - Trimming to ${TRIM_TO_LENGTH}bp..."
    
    prinseq-lite -fastq ${output_good} \
        -trim_to ${TRIM_TO_LENGTH} \
        -out_good ${trimmed_output} \
        -out_bad null 2>> ${LOG_FILE}
    
    if [ $? -ne 0 ]; then
        log "ERROR during trimming of ${file}"
        exit 1
    fi

    ####################################
    ### STEP 3: Quality Control ########
    ####################################
    log "Generating quality report for ${trimmed_output}..."
    
    fastqc -o ${QC_DIR} ${trimmed_output} 2>> ${LOG_FILE}
done

#########################################
### STEP 4: Consolidated QC report ######
#########################################
log "Generating MultiQC report..."

multiqc ${QC_DIR} -o ${QC_DIR} --filename multiqc_report_pacbio 2>> ${LOG_FILE}

log "=== PROCESSING COMPLETED ==="
log "Results located in: ${OUTPUT_DIR}"
log "Quality reports in: ${QC_DIR}"
log "Full log: ${LOG_FILE}"
