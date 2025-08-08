#!/bin/bash
# Script for ortholog and phylogeny analysis in Bacillus

# 1) Initial setup
echo "=== STARTING ORTHOLOG AND PHYLOGENY ANALYSIS ==="
BASE_DIR=$(pwd)
ORTHO_DIR="${BASE_DIR}/Bacillus_homologues"
SINGLE_COPY_DIR="${BASE_DIR}/single-copy"
LOG_FILE="${BASE_DIR}/log_analysis.txt"

# Create necessary directories
mkdir -p "${SINGLE_COPY_DIR}" "${ORTHO_DIR}"

# 2) Identify ortholog clusters with 1 copy per genome
echo -e "\n=== RUNNING get_homologues.pl ==="
get_homologues.pl -d "${BASE_DIR}/Bacillus/" -e -M -A -n 6 &> "${LOG_FILE}"

# 3) Prepare files for phylogeny
echo -e "\n=== PREPARING FILES FOR PHYLOGENY ==="

# Copy single-copy clusters
echo "Copying single-copy clusters to ${SINGLE_COPY_DIR}"
cp "${ORTHO_DIR}/BacillusvelezensisMEP218_f0_alltaxa_algOMCL_e1_"/* "${SINGLE_COPY_DIR}/"

# Change to working directory
cd "${SINGLE_COPY_DIR}" || exit

# Modify strain names in the files
echo "Modifying strain names in the files..."

## Amino acids: .faa
for f in *.faa; do
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.ori.gbk/|ori|Bacillus_sp_ARP23.ori.gbk/g' "$f"
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.cur.gbk/|cur|Bacillus_sp_ARP23.cur.gbk/g' "$f"
done

## Nucleotides: .fna
for f in *.fna; do
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.ori.gbk/|ori|Bacillus_sp_ARP23.ori.gbk/g' "$f"
    perl -pi.bak -e 's/\|\|Bacillus_sp_ARP23.cur.gbk/|cur|Bacillus_sp_ARP23.cur.gbk/g' "$f"
done

# Remove backup files
rm -f *.bak

# 4) Run phylogenetic analysis in Docker
echo -e "\n=== RUNNING PHYLOGENETIC ANALYSIS IN DOCKER ==="
echo "Starting get_phylomarkers container..."

# Docker command with volume mount
docker_cmd="sudo docker run --rm -it -v '${SINGLE_COPY_DIR}:/home/you/clusters' vinuesa/get_phylomarkers /bin/bash -c 'cd clusters && run_get_phylomarkers_pipeline.sh -R 1 -t DNA'"

echo "Executing:"
echo "${docker_cmd}"

# Execute Docker command
eval "${docker_cmd}"

# 5) Completion
echo -e "\n=== ANALYSIS COMPLETED ==="
echo "Results available at:"
echo "- Orthologs: ${ORTHO_DIR}"
echo "- Single-copy orthologs: ${SINGLE_COPY_DIR}"
echo "- Full log: ${LOG_FILE}"