#!/bin/bash

## === STEP 1: Initial Setup ===
# Define the location of the bacterial assembly file
ASSEMBLY="results/assemblies/unicycler_hybrid/assembly.fasta"

# Create the directory structure for the results
mkdir -p results/mapping/unicycler_hybrid/{illumina,ont,pacbio}

## === STEP 2: Indexing the Assembly ===
echo "1/5 - Creating reference assembly index..."
minimap2 -d reference.mmi $ASSEMBLY
# This creates an index file (reference.mmi) to speed up later alignments

## === STEP 3: Processing Illumina Data ===
echo "2/5 - Processing Illumina reads (paired-end)..."
minimap2 -ax sr $ASSEMBLY \
  data/processed/illumina/illumina_output_R1_paired.fastq \
  data/processed/illumina/illumina_output_R2_paired.fastq | \
samtools view -bS - | \
samtools sort -o results/mapping/unicycler_hybrid/illumina/illumina_mapped.sorted.bam
# -ax sr: indicates short reads
# Pipeline: alignment → BAM conversion → sorting by genomic position

# Indexing and generating statistics
samtools index results/mapping/unicycler_hybrid/illumina/illumina_mapped.sorted.bam
samtools flagstat results/mapping/unicycler_hybrid/illumina/illumina_mapped.sorted.bam > results/mapping/unicycler_hybrid/illumina/illumina_flagstat.txt
samtools coverage results/mapping/unicycler_hybrid/illumina/illumina_mapped.sorted.bam > results/mapping/unicycler_hybrid/illumina/illumina_coverage.txt

## === STEP 4: Processing Oxford Nanopore Data ===
echo "3/5 - Processing Oxford Nanopore reads..."
minimap2 -ax map-ont $ASSEMBLY \
  data/processed/corrected/ont_trim_504_trim_end_34499_minlen_1000_CORRECTED.fasta | \
samtools view -bS - | \
samtools sort -o results/mapping/unicycler_hybrid/ont/ont_mapped.sorted.bam
# -ax map-ont: optimized for ONT reads

# Indexing and statistics
samtools index results/mapping/unicycler_hybrid/ont/ont_mapped.sorted.bam
samtools flagstat results/mapping/unicycler_hybrid/ont/ont_mapped.sorted.bam > results/mapping/unicycler_hybrid/ont/ont_flagstat.txt
samtools coverage results/mapping/unicycler_hybrid/ont/ont_mapped.sorted.bam > results/mapping/unicycler_hybrid/ont/ont_coverage.txt

## === STEP 5: Processing PacBio Data (3 files) ===
echo "4/5 - Processing PacBio reads (3 files)..."

# Process each PacBio file individually
for i in {1..3}; do
  echo "Processing PacBio file ${i} of 3..."
  minimap2 -ax map-pb $ASSEMBLY \
    "data/processed/corrected/pacbio_cola50_trim34499_CORRECTED.${i}.subreads.fasta" | \
  samtools view -bS - | \
  samtools sort -o "results/mapping/unicycler_hybrid/pacbio/pacbio_${i}_mapped.sorted.bam"
  # -ax map-pb: parameter for PacBio data

  # Generate index and stats for each file
  samtools index "results/mapping/unicycler_hybrid/pacbio/pacbio_${i}_mapped.sorted.bam"
  samtools flagstat "results/mapping/unicycler_hybrid/pacbio/pacbio_${i}_mapped.sorted.bam" > "results/mapping/unicycler_hybrid/pacbio/pacbio_${i}_flagstat.txt"
  samtools coverage "results/mapping/unicycler_hybrid/pacbio/pacbio_${i}_mapped.sorted.bam" > "results/mapping/unicycler_hybrid/pacbio/pacbio_${i}_coverage.txt"
done

## === FINALIZATION ===
echo "5/5 - Pipeline completed successfully!"
echo "Results saved in:"
echo "- Illumina: results/mapping/unicycler_hybrid/illumina/"
echo "- ONT: results/mapping/unicycler_hybrid/ont/"
echo "- PacBio: results/mapping/unicycler_hybrid/pacbio/"
