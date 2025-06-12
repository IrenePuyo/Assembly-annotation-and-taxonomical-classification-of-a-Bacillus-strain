#!/bin/bash

## === PASO 1: Configuración inicial ===
# Define la ubicación del archivo de ensamblaje bacteriano
ENSAMBLAJE="results/assemblies/spades_full/contigs.fasta"

# Crea la estructura de directorios para los resultados
mkdir -p results/mapping/spades_full/{illumina,ont,pacbio}

## === PASO 2: Indexado del ensamblaje ===
echo "1/5 - Creando índice del ensamblaje de referencia..."
minimap2 -d referencia.mmi $ENSAMBLAJE
# Esto crea un archivo de índice (referencia.mmi) para acelerar los alineamientos posteriores

## === PASO 3: Procesamiento de datos Illumina ===
echo "2/5 - Procesando lecturas Illumina (paired-end)..."
minimap2 -ax sr $ENSAMBLAJE \
  data/processed/illumina/illumina_output_R1_paired.fastq \
  data/processed/illumina/illumina_output_R2_paired.fastq | \
samtools view -bS - | \
samtools sort -o results/mapping/spades_full/illumina/illumina_mapped.sorted.bam
# -ax sr: indica que son lecturas cortas (short reads)
# El pipeline: alineamiento → conversión a BAM → ordenamiento por posición genómica

# Indexado y generación de estadísticas
samtools index results/mapping/spades_full/illumina/illumina_mapped.sorted.bam
samtools flagstat results/mapping/spades_full/illumina/illumina_mapped.sorted.bam > results/mapping/spades_full/illumina/illumina_flagstat.txt
samtools coverage results/mapping/spades_full/illumina/illumina_mapped.sorted.bam > results/mapping/spades_full/illumina/illumina_coverage.txt

## === PASO 4: Procesamiento de datos Oxford Nanopore ===
echo "3/5 - Procesando lecturas Oxford Nanopore..."
minimap2 -ax map-ont $ENSAMBLAJE \
  data/processed/corrected/ont_trim_504_trim_end_34499_minlen_1000_CORRECTED.fasta | \
samtools view -bS - | \
samtools sort -o results/mapping/spades_full/ont/ont_mapped.sorted.bam
# -ax map-ont: parámetro optimizado para lecturas ONT

# Indexado y estadísticas
samtools index results/mapping/spades_full/ont/ont_mapped.sorted.bam
samtools flagstat results/mapping/spades_full/ont/ont_mapped.sorted.bam > results/mapping/spades_full/ont/ont_flagstat.txt
samtools coverage results/mapping/spades_full/ont/ont_mapped.sorted.bam > results/mapping/spades_full/ont/ont_coverage.txt

## === PASO 5: Procesamiento de datos PacBio (3 archivos) ===
echo "4/5 - Procesando lecturas PacBio (3 archivos)..."

# Procesamos cada archivo PacBio por separado
for i in {1..3}; do
  echo "Procesando archivo PacBio ${i} de 3..."
  minimap2 -ax map-pb $ENSAMBLAJE \
    "data/processed/corrected/pacbio_cola50_trim34499_CORRECTED.${i}.subreads.fasta" | \
  samtools view -bS - | \
  samtools sort -o "results/mapping/spades_full/pacbio/pacbio_${i}_mapped.sorted.bam"
  # -ax map-pb: parámetro para datos PacBio
  
  # Generamos índices y estadísticas para cada archivo
  samtools index "results/mapping/spades_full/pacbio/pacbio_${i}_mapped.sorted.bam"
  samtools flagstat "results/mapping/spades_full/pacbio/pacbio_${i}_mapped.sorted.bam" > "results/mapping/spades_full/pacbio/pacbio_${i}_flagstat.txt"
  samtools coverage "results/mapping/spades_full/pacbio/pacbio_${i}_mapped.sorted.bam" > "results/mapping/spades_full/pacbio/pacbio_${i}_coverage.txt"
done

## === FINALIZACIÓN ===
echo "5/5 - Pipeline completado exitosamente!"
echo "Resultados guardados en:"
echo "- Illumina: results/mapping/spades_full/illumina/"
echo "- ONT: results/mapping/spades_full/ont/"
echo "- PacBio: results/mapping/spades_full/pacbio/"