#!/bin/bash
# illumina_trim.sh - Preprocessing of de Illumina reads
# Cutadapt + Trimmomatic + Quality control

#############################
### 1. CONFIGURATION #######
#############################

# Directories
INPUT_DIR="data/raw/illumina"
OUTPUT_DIR="data/processed/trimmed"
QC_DIR="results/qc"
LOG_DIR="logs"
mkdir -p ${OUTPUT_DIR} ${QC_DIR} ${LOG_DIR}

# Input files
R1_IN="${INPUT_DIR}/diverse-ARP23_S33_L001_R1_001.fastq"
R2_IN="${INPUT_DIR}/diverse-ARP23_S33_L001_R2_001.fastq"

# Intermediate files (Cutadapt)
R1_CUTADAPT="${OUTPUT_DIR}/intermediate_R1_cutadapt.fastq"
R2_CUTADAPT="${OUTPUT_DIR}/intermediate_R2_cutadapt.fastq"

# Final files (Trimmomatic)
R1_OUT="${OUTPUT_DIR}/final_R1_trimmed.fastq"
R2_OUT="${OUTPUT_DIR}/final_R2_trimmed.fastq"
UNPAIRED_R1="${OUTPUT_DIR}/unpaired_R1.fastq"
UNPAIRED_R2="${OUTPUT_DIR}/unpaired_R2.fastq"

# Trimmomatic settings
TRIM_PARAMS="HEADCROP:15 MINLEN:50 AVGQUAL:28"

# Logging system
LOG_FILE="${LOG_DIR}/illumina_processing_$(date +%Y%m%d).log"
exec > >(tee -a ${LOG_FILE}) 2>&1

#############################
### 2. FUNCTIONS ###########
#############################

# Function to check input files
check_files() {
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            echo "ERROR: File not found: $file" | tee -a ${LOG_FILE}
            exit 1
        fi
    done
}

#############################
### 3. PROCESSING #######
#############################

echo "=== STARTING PROCESSING ===" | tee -a ${LOG_FILE}
date | tee -a ${LOG_FILE}

### 3.1 Cutadapt (adapter removal)
echo "[CUTADAPT] Removing adapters..." | tee -a ${LOG_FILE}

cutadapt -a "CTGTCTCTTATACACATCTCCGAGCCCACGAGAC" \
         -A "CTGTCTCTTATACACATCTGACGCTGCCGACGA" \
         -o ${R1_CUTADAPT} \
         -p ${R2_CUTADAPT} \
         ${R1_IN} \
         ${R2_IN} || { echo "Error in Cutadapt"; exit 1; }

### 3.2 Trimmomatic (quality filtering)
echo "[TRIMMOMATIC] Performing quality filtering..." | tee -a ${LOG_FILE}

trimmomatic PE -phred33 \
               ${R1_CUTADAPT} ${R2_CUTADAPT} \
               ${R1_OUT} ${UNPAIRED_R1} \
               ${R2_OUT} ${UNPAIRED_R2} \
               ${TRIM_PARAMS} || { echo "Error in Trimmomatic"; exit 1; }

### 3.3 Quality control after trimming
echo "[FASTQC] Running quality analysis..." | tee -a ${LOG_FILE}
fastqc -o ${QC_DIR} ${R1_OUT} ${R2_OUT}

### 3.4 Global report
echo "[MULTIQC] Generating global report..." | tee -a ${LOG_FILE}
multiqc ${QC_DIR} -o ${QC_DIR} --filename multiqc_report_final

#############################
### 4. FINALIZATION ########
#############################

echo "Processing completed successfully" | tee -a ${LOG_FILE}
echo "Final files in: ${OUTPUT_DIR}" | tee -a ${LOG_FILE}
echo "Quality reports in: ${QC_DIR}" | tee -a ${LOG_FILE}
echo "=== END OF PROCESS ===" | tee -a ${LOG_FILE}

date | tee -a ${LOG_FILE}
