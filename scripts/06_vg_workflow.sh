#!/bin/bash
#$ -l h_vmem=8G
#$ -l h_rt=02:00:00
#$ -cwd
#$ -o downsample.out
#$ -e downsample.err

# VG Graph Construction and Variant Calling Pipeline Script
# This script constructs a variation graph, aligns reads, calls variants,
# and prepares variant files for downstream analyses (e.g., PLINK, GCTA).

# Step 1: Create VG graph from the reference genome
echo "Step 1: Creating VG graph from reference..."
vg construct -r downsampled_data/genome_subset.fna -m 32 > results/variants/reference.vg

# Step 2: Index the graph for alignment
echo "Step 2: Indexing VG graph..."
vg index -x results/variants/reference.xg results/variants/reference.vg
vg prune results/variants/reference.vg > results/variants/reference.pruned.vg
vg index -g results/variants/reference.gcsa -k 16 results/variants/reference.pruned.vg

echo "VG graph construction completed."

# Step 3: VG alignment for each sample
echo "Step 3: Starting VG alignment..."

# Define samples to align
SAMPLES=("SRR2070512" "SRR2070597" "ERR4244435" "ERR4350100")

# Create alignment output directory if it doesn't exist
mkdir -p results/alignment

for SAMPLE in "${SAMPLES[@]}"; do
    echo "VG alignment for sample: $SAMPLE"
    
    # Map paired-end reads to the VG graph using the xg and gcsa indexes
    vg map -x results/variants/reference.xg -g results/variants/reference.gcsa \
        -f downsampled_data/${SAMPLE}_1_sub.fastq \
        -f downsampled_data/${SAMPLE}_2_sub.fastq \
        -t 4 > results/alignment/${SAMPLE}_vg.gam
    
    # Convert GAM to JSON (first 50 alignments only) for manual inspection or debugging
    vg view -a results/alignment/${SAMPLE}_vg.gam | head -n 50 > results/alignment/${SAMPLE}_vg_sample.json

    echo "Completed VG alignment for $SAMPLE"
done

echo "All VG alignments completed."

# Step 4: VG variant calling
echo "Step 4: VG variant calling..."

# Create variant calling output directory if it doesn't exist
mkdir -p results/variant_calling

cd results/alignment || { echo "Failed to enter alignment directory"; exit 1; }

for sample_gam in *.gam; do
    # Extract sample name by removing _vg.gam suffix
    sample_name="${sample_gam%_vg.gam}"

    echo "Calling variants for $sample_name"

    out_dir=../variant_calling

    # Augment the graph with each sample's GAM alignments to capture sample-specific variation
    vg augment ../variants/reference.vg \
        "$sample_gam" \
        -A "${out_dir}/${sample_name}_augmented.gam" > "${out_dir}/${sample_name}_augmented.vg"

    # Index the augmented graph for efficient querying
    vg index -x "${out_dir}/${sample_name}_augmented.xg" "${out_dir}/${sample_name}_augmented.vg"

    # Pack the augmented GAM to summarize coverage on the graph nodes
    vg pack -x "${out_dir}/${sample_name}_augmented.xg" \
        -g "${out_dir}/${sample_name}_augmented.gam" \
        -o "${out_dir}/${sample_name}.pack"

    # Call variants using the augmented graph and packing data
    vg call "${out_dir}/${sample_name}_augmented.xg" \
        -k "${out_dir}/${sample_name}.pack" > "${out_dir}/${sample_name}.vcf"

    # Compress and index VCF for downstream compatibility
    bgzip -f "${out_dir}/${sample_name}.vcf"
    bcftools index -f "${out_dir}/${sample_name}.vcf.gz"
done

cd ../variant_calling || exit

# Step 5: Rename sample IDs in VCF headers for clarity
echo -e "SAMPLE\tERR4244435" > ERR4244435.rename.txt
echo -e "SAMPLE\tERR4350100" > ERR4350100.rename.txt
echo -e "SAMPLE\tSRR2070512" > SRR2070512.rename.txt
echo -e "SAMPLE\tSRR2070597" > SRR2070597.rename.txt

bcftools reheader -s ERR4244435.rename.txt -o ERR4244435.renamed.vcf.gz ERR4244435.vcf.gz
bcftools reheader -s ERR4350100.rename.txt -o ERR4350100.renamed.vcf.gz ERR4350100.vcf.gz
bcftools reheader -s SRR2070512.rename.txt -o SRR2070512.renamed.vcf.gz SRR2070512.vcf.gz
bcftools reheader -s SRR2070597.rename.txt -o SRR2070597.renamed.vcf.gz SRR2070597.vcf.gz

# Index renamed VCFs
for file in *.renamed.vcf.gz; do
  bcftools index "$file"
done

# Step 6: Merge individual sample VCFs into a single multi-sample VCF
bcftools merge -Oz -o merged_salmon_variants.vcf.gz \
  ERR4244435.renamed.vcf.gz \
  ERR4350100.renamed.vcf.gz \
  SRR2070512.renamed.vcf.gz \
  SRR2070597.renamed.vcf.gz

bcftools index merged_salmon_variants.vcf.gz

# Output sample list from merged VCF for confirmation
bcftools query -l merged_salmon_variants.vcf.gz

# Step 7: Filter variants by quality
echo "Filtering variants by quality (QUAL > 20)..."
bcftools filter -i 'QUAL>20' \
  merged_salmon_variants.vcf.gz \
  -Oz -o filtered_merged_salmon_variants.vcf.gz

bcftools index filtered_merged_salmon_variants.vcf.gz

# Step 8: Convert filtered VCF to PLINK format
echo "Converting filtered VCF to PLINK format..."

# --allow-extra-chr and --chr-set 29 used because salmon genome includes non-standard chromosomes or contigs
plink --vcf filtered_merged_salmon_variants.vcf.gz \
  --make-bed \
  --out salmon_variants_plink \
  --allow-extra-chr \
  --chr-set 29 \
  --maf 0.05 \
  --geno 0.1 \
  --hwe 0.001

# Step 9: Prepare phenotype file for PLINK
cat > salmon_type.pheno << EOF
SRR2070512 SRR2070512 1
SRR2070597 SRR2070597 1
ERR4244435 ERR4244435 2
ERR4350100 ERR4350100 2
EOF

# Step 10: Recreate PLINK binary files including phenotype data
plink --bfile salmon_variants_plink \
  --pheno salmon_type.pheno \
  --make-bed \
  --allow-extra-chr \
  --out salmon_with_pheno

# Print a quick check of sample IDs and phenotypes
awk '{print $1, $2, $6}' salmon_with_pheno.fam

# Step 11: Prepare population file for downstream analysis (e.g., GCTA)
cat > salmon_populations.txt << EOF
SRR2070512 1
SRR2070597 1
ERR4244435 2
ERR4350100 2
EOF

# Step 12: Generate variant statistics summary
echo "Variant Statistics:" > vg_summary.txt
echo "===================" >> vg_summary.txt
bcftools stats filtered_merged_salmon_variants.vcf.gz | grep "number of records\|number of SNPs" >> vg_summary.txt
echo "" >> vg_summary.txt
echo "PLINK SNP Count:" >> vg_summary.txt
wc -l salmon_with_pheno.bim >> vg_summary.txt

echo "VG pipeline completed. Data is ready for downstream analyses such as GCTA."
