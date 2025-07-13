# SalmoGraph: Atlantic Salmon Population Genomics Using Variation Graph Toolkit (VG) and GCTA

This repository presents a genomic workflow to explore publicly available data from Atlantic Salmon (*Salmo salar*) populations using Variation Graph (VG) tools and downstream quantitative genetic analysis using GCTA.

## Before You Begin

This project was developed and tested on a High Performance Computing (HPC) cluster. It assumes use of resource allocation via job schedulers and the need for interactive sessions. Please update paths, module loading, and execution methods according to your local system or cloud environment.

## Background

The Atlantic Salmon (*Salmo salar*) is a species of ecological, cultural, and economic significance.

Understanding genetic diversity across its wild and farmed populations is essential for conservation and aquaculture.

This project aims to:

- Analyse publicly available *Salmo salar* whole-genome resequencing data
- Use VG (Variation Graph Toolkit) to construct variation-aware graphs and align short-read sequences
- Prepare and assess output suitable for quantitative genetic analysis via GCTA

## Software and Tools Used

- [Conda](https://docs.conda.io/en/latest/) for environment and package management, including bioinformatics tools like FastQC, Trimmomatic, Seqtk, BWA, Samtools, BCFtools, and PLINK
- [VG Toolkit](https://github.com/vgteam/vg) (version 1.57.0) — downloaded as a standalone binary for graph-based variant analysis
- [GCTA](http://cnsgenomics.com/software/gcta/) (version 1.94.4) — downloaded as a binary for quantitative genetic analysis
- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) — quality control of sequencing reads
- [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic) — read trimming and adapter removal
- [Seqtk](https://github.com/lh3/seqtk) — fastq processing toolkit
- [BWA](http://bio-bwa.sourceforge.net/) — sequence alignment tool
- [Samtools](http://www.htslib.org/) — manipulation of alignments in SAM/BAM format
- [BCFtools](http://samtools.github.io/bcftools/) — variant calling and manipulation
- [PLINK](https://www.cog-genomics.org/plink/) — population genetics and association analysis
> **Note:** VG and GCTA binaries are downloaded separately and must be run from the download directory or added to your system PATH. The conda environment `salmon_env` manages the other tools and dependencies.

## Workflow Overview

### 1. Set Up the Environment

Environment setup was handled using shell scripts on an HPC cluster. Resources were requested interactively or via submission scripts.

### 2. Download Sample Data

The data used in this project is from: **Barson et al. (2020), Nature Communications**: [https://www.nature.com/articles/s41467-020-18972-x](https://www.nature.com/articles/s41467-020-18972-x)  
Credits to the authors for making this valuable dataset openly available.

### 2. Download Reference Genome

Download the complete genomic.fna of the Atlantic Salmon (*Salmo salar*) reference genome (Genome assembly Ssal_v3.1) dated Apr 21, 2021 from NCBI.

### 3. Perform Quality Control and Trimming

FastQC was used for assessing raw read quality. Trimmomatic (paired-end mode) was used for adapter and quality trimming. Note that trimming was selectively applied only to 2 samples (ERR4244435, ERR4350100) where needed, but Trimmomatic PE required trimming both ends. Hence, the trimmed reads for these 2 samples were used along with the raw reads for the other 2 samples (SRR2070512, SRR2070597).

### 4. Downsample (if needed)

Downsampling was performed to reduce computational load during graph alignment and variant calling. It also allows for faster pipeline testing and debugging with representative data subsets.

### 5. Perform VG Graph Construction and Alignment

Graph-based variant-aware alignment was performed using VG:

- Constructed a variation graph from reference and VCF
- Indexed and pruned the graph
- Mapped reads using `vg map`

### Sample Information

The sample metadata used in the analysis is stored in `Salmo_salar_sample_info.txt`.

Below is the summary:

| SampleID   | Population   | Type   | Origin | Latitude | Longitude |
| ---------- | ------------ | ------ | ------ | -------- | --------- |
| SRR2070512 | Chile_Farm   | Farmed | Chile  | -33.0    | -71.0     |
| SRR2070597 | Chile_Farm   | Farmed | Chile  | -33.0    | -71.0     |
| ERR4244435 | Norway_Wild  | Wild   | Norway | 69.968   | 23.375    |
| ERR4350100 | Norway_Wild  | Wild   | Norway | 69.968   | 23.375    |

## Repository Contents

### Scripts

This repository contains the following shell scripts stored in the `scripts/` folder:

| Script Name                 | Description                                                                                                         |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| 01_setup_environment.sh     | Load required modules and create virtual environments if needed                                                     |
| 02_download_data.sh         | Download fastq files using SRA toolkit (fasterq-dump)                                                               |  
| 03_donwload_ref_geneome.sh  | Download *Salmo salar* reference genome from NCBI                                                                   |
| 04_qc_trimming_qc.sh        | Perform initial QC using FastQC, Trim reads using Trimmomatic (only selected samples), pre-trimming QC using FastQC |
| 05_downsampling_indexing.sh | Downsample the sample reads to increase efficiency of analysis                                                      |
| 06_vg_workflow.sh           | Build VG graph, prune, index, and perform mapping using VG tools                                                    |

### Results Folder Structure

```bash
results/
├── fastqc_results/           # FastQC outputs for raw reads
├── trimmed_fastqc_results/   # FastQC outputs for trimmed reads
├── vg_analysis_results/      # Graph and indexing results
│   ├── reference.vg          # Initial variation graph
│   ├── reference.xg          # Indexed version of the graph
│   ├── reference.pruned.vg   # Simplified version of the graph
│   └── vg_alignments/        # Alignment results (first 50 alignments per sample)
```

## Future Directions

- Generate VCF from VG alignments and perform genotype refinement.
- Use GCTA to build the Genetic Relationship Matrix (GRM) and create visualisations such as Manhattan plots.
- Explore QTL (Quantitative Trait Loci) mapping, identifying genomic regions associated with complex traits like growth rate and disease resistance (if suitable phenotype data and a larger sample size become available).
  
### ________________
### by Anooraag Basu
