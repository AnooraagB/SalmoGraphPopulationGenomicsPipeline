#!/bin/bash

# SalmoGraph: Environment setup for population genomics pipeline
# This script installs required software via conda and downloads VG and GCTA binaries.
# Run on Linux. Requires conda installed.

echo "Creating and activating conda environment 'salmon_env' with Python 3.10"
conda create -n salmon_env python=3.10 -y
echo "To activate environment, run:"
echo "conda activate salmon_env"
echo ""

echo "Adding conda channels for bioinformatics tools"
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

echo "Installing packages: fastqc, trimmomatic, seqtk, bwa, samtools, bcftools, plink"
conda install -n salmon_env -y fastqc trimmomatic seqtk bwa samtools bcftools plink

echo ""
echo "Downloading VG toolkit binary (version 1.57.0)"
wget https://github.com/vgteam/vg/releases/download/v1.57.0/vg -O vg
chmod +x vg
echo "VG binary downloaded. You can run it as './vg' from this directory."
echo "Check version:"
./vg version || echo "VG binary may not run. Ensure dependencies like protobuf are installed."
echo ""

echo "Downloading and setting up GCTA (version 1.94.4)"
wget https://yanglab.westlake.edu.cn/software/gcta/bin/gcta-1.94.4-linux-kernel-3-x86_64.zip
unzip gcta-1.94.4-linux-kernel-3-x86_64.zip
chmod +x gcta-1.94.4-linux-kernel-3-x86_64/gcta64
echo "GCTA binary downloaded to 'gcta-1.94.4-linux-kernel-3-x86_64/gcta64'"
echo ""

echo "IMPORTANT:"
echo "Add VG and GCTA to your PATH manually by running:"
echo "export PATH=\$PATH:$(pwd):$(pwd)/gcta-1.94.4-linux-kernel-3-x86_64"
echo "You may want to add this line to your ~/.bashrc or ~/.zshrc to make it permanent."
echo ""

echo "Environment setup complete."
echo "Activate conda env with: conda activate salmon_env"
echo "Run VG as ./vg and GCTA as ./gcta-1.94.4-linux-kernel-3-x86_64/gcta64 or add them to your PATH."
