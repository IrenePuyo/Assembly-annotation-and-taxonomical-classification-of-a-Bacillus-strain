#!/bin/bash

# PGAP annotation for curated genome assembly

INPUT_GENOME="../../assemblies/unicycler_hybrid/assembly.fasta"
OUTPUT_DIR="../../annot/pgap"
SPECIES="'Bacillus velezensis'"

echo "Starting PGAP annotation for curated genome assembly"
echo "Input genome: $INPUT_GENOME"
echo "Output directory: $OUTPUT_DIR"

# Run PGAP with taxcheck and debug mode
sudo /home/contrera/soft/pgap.py -r -o $OUTPUT_DIR -g $INPUT_GENOME -s $SPECIES --taxcheck -d

if [ $? -eq 0 ]; then
    echo "PGAP annotation completed successfully for curated genome"
else
    echo "Error in PGAP annotation for curated genome"
    exit 1
fi