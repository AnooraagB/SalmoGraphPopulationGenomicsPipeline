#!/bin/bash

# Set directory to store reference genome (update as needed)
REF_DIR="$HOME/SalmoGraph/reference_genome"

# Create directory if it doesn't exist
mkdir -p "$REF_DIR"
cd "$REF_DIR" || { echo "Failed to enter $REF_DIR"; exit 1; }

# Download Atlantic Salmon reference genome (Ssal v3.1)
echo "Downloading Atlantic Salmon reference genome..."
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/905/237/065/GCF_905237065.1_Ssal_v3.1/GCF_905237065.1_Ssal_v3.1_genomic.fna.gz

# Uncompress the genome fasta file
echo "Uncompressing the downloaded genome file..."
gunzip -f *.gz

echo "Reference genome downloaded and extracted in $REF_DIR"
