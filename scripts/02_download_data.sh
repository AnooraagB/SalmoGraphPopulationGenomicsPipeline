#!/bin/bash
#$ -l h_vmem=64G
#$ -l h_rt=08:00:00
#$ -cwd
#$ -o download.out
#$ -e download.err

# Script to download raw FASTQ files from SRA using fasterq-dump
# Selected 2 farmed and 2 wild Atlantic salmon samples for comparison
# Source dataset:
# Bertolotti et al. (2020) "The structural variation landscape in 492 Atlantic salmon genomes"
# Nature Communications 11, 5176. https://doi.org/10.1038/s41467-020-18972-x

FASTERQ_DUMP="$HOME/sratoolkit.3.2.1-ubuntu64/bin/fasterq-dump"

mkdir -p fastq

samples=(
  SRR2070512  # Farmed
  SRR2070597  # Farmed
  ERR4350100  # Wild
  ERR4244435  # Wild
)

for sample in "${samples[@]}"; do
  echo "Downloading $sample ..."
  $FASTERQ_DUMP --split-files --outdir fastq "$sample"
  echo "$sample download finished."
done

echo "All downloads completed."
