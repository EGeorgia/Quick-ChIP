#!/bin/bash

# Specify parameters:
usage() { echo -e "
+-------------------------------------------------------+
|                       QUICK-CHIP		        |
|           Fastq -> bigwigs for ChIP-seq data          |
|             Emily Georgiades, August 2021             |
+-------------------------------------------------------+
Notes: sample name should be consistent with fastq naming.\n
Use following flags:" && grep " .)\ #" $0; exit 0; }
[ $# -eq 0 ] && usage
while getopts ":f:d:r:g:p:" arg; do
  case $arg in
    f) # Specify sample name (e.g. clone_celltype_condition_rep).
	SAMPLE=${OPTARG};;
    d) # Specify directory containing gun-zipped fastqs.
  READS=${OPTARG};;
    r) # Specify whether reads are 'single' or 'paired'
	DATA=${OPTARG};;
    g) # Specify genome build (mm39 or hg38).
	GENOME=${OPTARG};;
    p) # Give path to public directory where bigwigs will be saved (not including /datashare/).
	public_dir=${OPTARG};;
    h) # Display help.
      usage
      exit 0
      ;;
  esac
done

module load cutadapt
module load ucsctools
module load bowtie2
module load sambamba
module load samtools

start="$(date)"

echo ""
echo "+--------------------------------------------------------------+"
echo "|                        QUICK-CHIP                            |"
echo "|          Run started:  "$start"                              |"
echo "+--------------------------------------------------------------+"
echo ""

# Determine which bt2 directory to use:
if [ $GENOME == "mm39" ]; then
   BT2DIR="/stopgap/databank/igenomes/Mus_musculus/UCSC/mm39/Sequence/Bowtie2Index"
elif [ $GENOME == "hg38" ]; then
   BT2DIR="/stopgap/databank/igenomes/Homo_sapiens/UCSC/hg38/Sequence/Bowtie2Index"
else
  echo "Incorrect genome entered, choose either mm39 or hg38."
fi

# Preliminary step: adapter trimming
# NEBNext® Ultra™ and NEBNext® Ultra™ II DNA Library Prep Kits for Illumina®
# Step 1: Align single ot paired end reads using Bowtie2

# For single-end reads:
if [ $READS == "single" ]; then
   echo "Preliminary step: adapter trimming of single-ended reads"
   cutadapt -a GATCGGAAGAGCACACGT ${DATA}/${SAMPLE}.fastq.gz | cutadapt -m 18 -o ${DATA}/${SAMPLE}_trimmed.fastq.gz -
   echo " Step 1: Aligning single-end reads using Bowtie2..."
   bowtie2 -x ${BT2DIR}/genome -U ${DATA}/${SAMPLE}_trimmed.fastq.gz -S ${SAMPLE}.sam

# For paired-end reads:
elif [ $READS == "paired" ]; then
   echo "Preliminary step: adapter trimming of paired-ended reads"
   # READ1
   cutadapt -a GATCGGAAGAGCACACGT ${DATA}/${SAMPLE}_R1.fastq.gz | cutadapt -m 18 -o ${DATA}/${SAMPLE}_R1_trimmed.fastq.gz -
   echo "READ1 adapters trimmed."
   # READ2
   cutadapt -a GATCGGAAGAGCACACGT ${DATA}/${SAMPLE}_R2.fastq.gz | cutadapt -m 18 -o ${DATA}/${SAMPLE}_R2_trimmed.fastq.gz -
   echo "READ2 adapters trimmed."

   echo " Step 1: Aligning paired-end reads using Bowtie2..."
   bowtie2 -x ${BT2DIR}/genome -1 ${DATA}/${SAMPLE}_R1_trimmed.fastq.gz  -2 $DATA/${SAMPLE}_R2_trimmed.fastq.gz -S ${SAMPLE}.sam

else
  echo "Paired or single-end reads must be specified."
fi

# Step 2: Sam to Bam conversion
echo " Step 2: Sam to Bam conversion"
samtools view -S -b ${SAMPLE}.sam > ${SAMPLE}.bam

# Step 3: sort bamfile by genomic coordinate
echo " Step 3: Sorting bamfile"
sambamba sort -o ${SAMPLE}_sorted.bam ${SAMPLE}.bam

# Step 4: remove duplicates
echo " Step 4: Removing duplicates"
sambamba markdup -r ${SAMPLE}_sorted.bam ${SAMPLE}_sorted_rmdup.bam

# Step 5: index bam
echo " Step 5: Indexing bamfile"
sambamba index ${SAMPLE}_sorted_rmdup.bam ${SAMPLE}.bai

# Step 6: creating a bigwig using DeepTools
echo " Step 6: Creating bigwig"
bamCoverage -b ${SAMPLE}_sorted_rmdup.bam -o ${SAMPLE}.bw

# Step 7: copy bigwigs to datashare folder to view on ucsc genome browsed
cp ${SAMPLE}.bw /datashare/${public_dir}
echo ""
echo "Copy + paste link into UCSC genome browser:"
echo "bigDataUrl=http://sara.molbiol.ox.ac.uk/public/${public_dir}/${SAMPLE}.bw"
echo ""

echo "Cleaning up..."
rm ${SAMPLE}*.bam
rm ${SAMPLE}*.sam
rm ${SAMPLE}*.bai

end="$(date)"
echo ""
echo "Run complete:" "$end"
echo "+--------------------------------------------------------------+"
echo "################################################################"
echo ""
