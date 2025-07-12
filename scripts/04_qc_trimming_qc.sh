#!/bin/bash
#$ -l h_vmem=32G
#$ -l h_rt=06:00:00
#$ -cwd
#$ -o trimming_fastqc.out
#$ -e trimming_fastqc.err

# Set paths (update as needed)
INPUT_DIR="$HOME/SalmoGraph/fastq"
TRIMMED_DIR="$HOME/SalmoGraph/trimmed_results"
FASTQC_RAW_DIR="$HOME/SalmoGraph/raw_fastqc_report"
FASTQC_TRIMMED_DIR="$HOME/SalmoGraph/trimmed_fastqc_report"

# Create output directories
mkdir -p "$TRIMMED_DIR"
mkdir -p "$FASTQC_RAW_DIR"
mkdir -p "$FASTQC_TRIMMED_DIR"

# Load conda environment
source ~/.bashrc
conda activate salmon_env

echo "Running initial FastQC on raw FASTQ files..."
fastqc "$INPUT_DIR"/*.fastq -o "$FASTQC_RAW_DIR"

echo "Starting trimming..."

# Trimming ERR4244435 (reverse read needs trimming to 124 bp)
trimmomatic PE \
  "$INPUT_DIR/ERR4244435_1.fastq" "$INPUT_DIR/ERR4244435_2.fastq" \
  "$TRIMMED_DIR/ERR4244435_1_paired.fastq" "$TRIMMED_DIR/ERR4244435_1_unpaired.fastq" \
  "$TRIMMED_DIR/ERR4244435_2_paired.fastq" "$TRIMMED_DIR/ERR4244435_2_unpaired.fastq" \
  CROP:124 MINLEN:36

# Trimming ERR4350100 (reverse read needs trimming to 130 bp)
trimmomatic PE \
  "$INPUT_DIR/ERR4350100_1.fastq" "$INPUT_DIR/ERR4350100_2.fastq" \
  "$TRIMMED_DIR/ERR4350100_1_paired.fastq" "$TRIMMED_DIR/ERR4350100_1_unpaired.fastq" \
  "$TRIMMED_DIR/ERR4350100_2_paired.fastq" "$TRIMMED_DIR/ERR4350100_2_unpaired.fastq" \
  CROP:130 MINLEN:36

echo "Running FastQC on trimmed paired reads..."
fastqc "$TRIMMED_DIR"/*_paired.fastq -o "$FASTQC_TRIMMED_DIR"

echo "All FastQC and trimming steps complete. Outputs located in:"
echo "  → Raw FastQC reports: $FASTQC_RAW_DIR"
echo "  → Trimmed FASTQ: $TRIMMED_DIR"
echo "  → Trimmed FastQC reports: $FASTQC_TRIMMED_DIR"

