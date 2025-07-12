#!/bin/bash
#$ -l h_vmem=8G
#$ -l h_rt=02:00:00
#$ -cwd
#$ -o downsample.out
#$ -e downsample.err

# VG Graph Construction and Alignment Script

# Step 1: Create VG graph from the reference genome
echo "Creating VG graph from reference..."
vg construct -r downsampled_data/genome_subset.fna -m 32 > results/variants/reference.vg

# Step 2: Index the graph for alignment
echo "Indexing VG graph..."
vg index -x results/variants/reference.xg results/variants/reference.vg
vg prune results/variants/reference.vg > results/variants/reference.pruned.vg
vg index -g results/variants/reference.gcsa -k 16 results/variants/reference.pruned.vg

echo "VG graph construction completed."

# Step 3: VG alignment for each sample
echo "Starting VG alignment..."

# Define samples to align
SAMPLES=("SRR2070512" "SRR2070597" "ERR4244435" "ERR4350100")

# Create alignment output directory if it doesn't exist
mkdir -p results/alignment

for SAMPLE in "${SAMPLES[@]}"; do
    echo "VG alignment for sample: $SAMPLE"
    
    # Map reads to graph
    vg map -x results/variants/reference.xg -g results/variants/reference.gcsa \
        -f downsampled_data/${SAMPLE}_1_sub.fastq \
        -f downsampled_data/${SAMPLE}_2_sub.fastq \
        -t 4 > results/alignment/${SAMPLE}_vg.gam
    
    # Convert GAM to JSON (first 50 alignments only) for inspection
    vg view -a results/alignment/${SAMPLE}_vg.gam | head -n 50 > results/alignment/${SAMPLE}_vg_sample.json

    echo "Completed VG alignment for $SAMPLE"
done

echo "All VG alignments completed."

# Note: Further steps (e.g., variant calling, GCSA-to-VCF conversion) to follow.

