#!/bin/bash
# Phylogenetic analysis with MAFFT.

###########################
### INITIAL CONFIGURATION ###
###########################

# Directories (will be created automatically)
INPUT_DIR="data/phylogeny"
OUTPUT_DIR="results/phylogeny"
LOG_FILE="phylogenetic_analysis.log"

# Input file
MULTIFASTA="${INPUT_DIR}/multifasta.fasta"

#######################
### INTERNAL FUNCTIONS ###
#######################

# Function to create directories
create_dirs() {
    mkdir -p "$1" || {
        echo "ERROR: Could not create directory $1"
        exit 1
    }
}

# Logging function
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

########################
### MAIN EXECUTION ###
########################

# 1. Initial setup
create_dirs "$OUTPUT_DIR"
log "=== STARTING PHYLOGENETIC ANALYSIS ==="

# 2. Check input file
if [ ! -f "$MULTIFASTA" ]; then
    log "ERROR: Input file not found: $MULTIFASTA"
    log "Please place your sequences in FASTA format in this directory"
    exit 1
fi

# 3. Multiple sequence alignment with MAFFT
log "Running MAFFT for multiple sequence alignment..."
mafft --localpair --maxiterate 1000 \
      --thread -1 \
      "$MULTIFASTA" > "${OUTPUT_DIR}/aligned.fasta" 2>> "$LOG_FILE"

# Check success
if [ $? -ne 0 ] || [ ! -s "${OUTPUT_DIR}/aligned.fasta" ]; then
    log "ERROR: MAFFT alignment failed"
    exit 1
fi
log "Alignment completed: ${OUTPUT_DIR}/aligned.fasta"

# 4. Phylogenetic tree construction with IQ-TREE2
log "Building phylogenetic tree with IQ-TREE2..."
iqtree2 -s "${OUTPUT_DIR}/aligned.fasta" \
        -m MFP \
        -bb 1000 \
        -alrt 1000 \
        -nt AUTO \
        -pre "${OUTPUT_DIR}/phylogenetic_tree" \
        2>> "$LOG_FILE"

# Check results
if [ ! -f "${OUTPUT_DIR}/phylogenetic_tree.treefile" ]; then
    log "ERROR: Tree construction failed"
    exit 1
fi

#################
### COMPLETION ###
#################

log "=== ANALYSIS COMPLETED SUCCESSFULLY ==="
log "Main results:"
log "1. Alignment: ${OUTPUT_DIR}/aligned.fasta"
log "2. Phylogenetic tree: ${OUTPUT_DIR}/phylogenetic_tree.treefile"
log "3. Full report: ${OUTPUT_DIR}/phylogenetic_tree.iqtree"
log "You can visualize the tree with FigTree or iTOL"

exit 0