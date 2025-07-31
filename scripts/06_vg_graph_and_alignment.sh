#!/bin/bash
#$ -l h_vmem=8G
#$ -l h_rt=02:00:00
#$ -cwd
#$ -o vg_graph_alignment.out
#$ -e vg_graph_alignment.err

# VG Graph Construction and Alignment Script

echo "Step 1: Creating VG graph from reference..."
mkdir -p results/variants
vg construct -r downsampled_data/genome_subset.fna -m 32 > results/variants/reference.vg

echo "Step 2: Indexing VG graph..."
vg index -x results/variants/reference.xg results/variants/reference.vg
vg prune results/variants/reference.vg > results/variants/reference.pruned.vg
vg index -g results/variants/reference.gcsa -k 16 results/variants/reference.pruned.vg

echo "VG graph construction completed."

echo "Step 3: Starting VG alignment..."
SAMPLES=("SRR2070512" "SRR2070597" "ERR4244435" "ERR4350100")

mkdir -p results/alignment

for SAMPLE in "${SAMPLES[@]}"; do
    echo "VG alignment for sample: $SAMPLE"
    vg map -x results/variants/reference.xg -g results/variants/reference.gcsa \
        -f downsampled_data/${SAMPLE}_1_sub.fastq \
        -f downsampled_data/${SAMPLE}_2_sub.fastq \
        -t 4 > results/alignment/${SAMPLE}_vg.gam
    
    vg view -a results/alignment/${SAMPLE}_vg.gam | head -n 50 > results/alignment/${SAMPLE}_vg_sample.json

    echo "Completed VG alignment for $SAMPLE"
done

echo "VG alignment completed."
