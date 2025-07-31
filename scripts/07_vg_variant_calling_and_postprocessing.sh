#!/bin/bash
#$ -l h_vmem=32G
#$ -l h_rt=05:00:00
#$ -cwd
#$ -o vg_variant_calling.out
#$ -e vg_variant_calling.err

# VG Variant Calling and Postprocessing Script

mkdir -p results/variant_calling
cd results/alignment || { echo "Failed to enter alignment directory"; exit 1; }

echo "Step 4: VG variant calling..."

for sample_gam in *.gam; do
    sample_name="${sample_gam%_vg.gam}"
    echo "Calling variants for $sample_name"
    out_dir=../variant_calling

    vg augment ../variants/reference.vg \
        "$sample_gam" \
        -A "${out_dir}/${sample_name}_augmented.gam" > "${out_dir}/${sample_name}_augmented.vg"

    vg index -x "${out_dir}/${sample_name}_augmented.xg" "${out_dir}/${sample_name}_augmented.vg"

    vg pack -x "${out_dir}/${sample_name}_augmented.xg" \
        -g "${out_dir}/${sample_name}_augmented.gam" \
        -o "${out_dir}/${sample_name}.pack"

    vg call "${out_dir}/${sample_name}_augmented.xg" \
        -k "${out_dir}/${sample_name}.pack" > "${out_dir}/${sample_name}.vcf"

    bgzip -f "${out_dir}/${sample_name}.vcf"
    bcftools index -f "${out_dir}/${sample_name}.vcf.gz"
done

cd ../variant_calling || exit

echo "Step 5: Renaming sample IDs in VCF headers..."

for SAMPLE in ERR4244435 ERR4350100 SRR2070512 SRR2070597; do
  echo -e "SAMPLE\t$SAMPLE" > ${SAMPLE}.rename.txt
  bcftools reheader -s ${SAMPLE}.rename.txt -o ${SAMPLE}.renamed.vcf.gz ${SAMPLE}.vcf.gz
done

for file in *.renamed.vcf.gz; do
  bcftools index "$file"
done

echo "Step 6: Merging sample VCFs..."

bcftools merge -Oz -o merged_salmon_variants.vcf.gz \
  ERR4244435.renamed.vcf.gz \
  ERR4350100.renamed.vcf.gz \
  SRR2070512.renamed.vcf.gz \
  SRR2070597.renamed.vcf.gz

bcftools index merged_salmon_variants.vcf.gz

echo "Samples in merged VCF:"
bcftools query -l merged_salmon_variants.vcf.gz

echo "Step 7: Filtering variants by quality (QUAL > 20)..."

bcftools filter -i 'QUAL>20' \
  merged_salmon_variants.vcf.gz \
  -Oz -o filtered_merged_salmon_variants.vcf.gz

bcftools index filtered_merged_salmon_variants.vcf.gz

echo "Step 8: Converting filtered VCF to PLINK format..."

plink --vcf filtered_merged_salmon_variants.vcf.gz \
  --make-bed \
  --out salmon_variants_plink \
  --allow-extra-chr \
  --chr-set 29 \
  --maf 0.05 \
  --geno 0.1 \
  --hwe 0.001

echo "Step 9: Preparing phenotype file..."
cat > salmon_type.pheno << EOF
SRR2070512 SRR2070512 1
SRR2070597 SRR2070597 1
ERR4244435 ERR4244435 2
ERR4350100 ERR4350100 2
EOF

echo "Step 10: Adding phenotype data to PLINK files..."

plink --bfile salmon_variants_plink \
  --pheno salmon_type.pheno \
  --make-bed \
  --allow-extra-chr \
  --out salmon_with_pheno

echo "Sample IDs and phenotypes:"
awk '{print $1, $2, $6}' salmon_with_pheno.fam

echo "Step 11: Preparing population file..."

cat > salmon_populations.txt << EOF
SRR2070512 1
SRR2070597 1
ERR4244435 2
ERR4350100 2
EOF

echo "Step 12: Generating variant statistics summary..."

echo "Variant Statistics:" > vg_summary.txt
echo "===================" >> vg_summary.txt
bcftools stats filtered_merged_salmon_variants.vcf.gz | grep "number of records\|number of SNPs" >> vg_summary.txt
echo "" >> vg_summary.txt
echo "PLINK SNP Count:" >> vg_summary.txt
wc -l salmon_with_pheno.bim >> vg_summary.txt

echo "VG variant calling and processing pipeline completed."
