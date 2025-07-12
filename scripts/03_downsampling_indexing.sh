#!/bin/bash

# Adjust resource settings based on your system and dataset size.

# Define directories (update as needed)
FASTQ_DIR="$HOME/SalmoGraph/fastq"
TRIMMED_DIR="$HOME/SalmoGraph/trimmed_results"
REF_DIR="$HOME/SalmoGraph/reference_genome"
DOWNSAMPLE_DIR="$HOME/SalmoGraph/downsampled_data"

# Create output directory if it doesn't exist
mkdir -p "$DOWNSAMPLE_DIR"

echo "Starting downsampling of FASTQ files to 1 million reads each..."

# Downsample paired-end FASTQ files (raw)
seqtk sample -s100 "$FASTQ_DIR/SRR2070512_1.fastq" 1000000 > "$DOWNSAMPLE_DIR/SRR2070512_1_sub.fastq"
seqtk sample -s100 "$FASTQ_DIR/SRR2070512_2.fastq" 1000000 > "$DOWNSAMPLE_DIR/SRR2070512_2_sub.fastq"

seqtk sample -s100 "$FASTQ_DIR/SRR2070597_1.fastq" 1000000 > "$DOWNSAMPLE_DIR/SRR2070597_1_sub.fastq"
seqtk sample -s100 "$FASTQ_DIR/SRR2070597_2.fastq" 1000000 > "$DOWNSAMPLE_DIR/SRR2070597_2_sub.fastq"

# Downsample trimmed paired-end FASTQ files
seqtk sample -s100 "$TRIMMED_DIR/ERR4244435_1_paired.fastq" 1000000 > "$DOWNSAMPLE_DIR/ERR4244435_1_sub.fastq"
seqtk sample -s100 "$TRIMMED_DIR/ERR4244435_2_paired.fastq" 1000000 > "$DOWNSAMPLE_DIR/ERR4244435_2_sub.fastq"

seqtk sample -s100 "$TRIMMED_DIR/ERR4350100_1_paired.fastq" 1000000 > "$DOWNSAMPLE_DIR/ERR4350100_1_sub.fastq"
seqtk sample -s100 "$TRIMMED_DIR/ERR4350100_2_paired.fastq" 1000000 > "$DOWNSAMPLE_DIR/ERR4350100_2_sub.fastq"

echo "Downsampling complete."

echo "Creating a smaller subset of the reference genome (first 100,000 lines)..."
head -n 100000 "$REF_DIR/genomic.fna" > "$DOWNSAMPLE_DIR/genome_subset.fna"

echo "Indexing the subset reference genome..."
bwa index "$DOWNSAMPLE_DIR/genome_subset.fna"
samtools faidx "$DOWNSAMPLE_DIR/genome_subset.fna"

echo "Downsampling and reference indexing completed."

