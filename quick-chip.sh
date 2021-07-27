#!/bin/bash

# Specify parameters:
usage() { echo -e "
+-------------------------------------------------------+
|                      QUICK-CHIP                       |
| Fastq->bigwigs for a quick look at your ChIP-seq data |
|                Emily Georgiades, July 2021            |
+-------------------------------------------------------+
Notes: sample name should be consistent with fastq naming.\n
Use following flags:" && grep " .)\ #" $0; exit 0; }
[ $# -eq 0 ] && usage
while getopts ":f:d:g:p:" arg; do
  case $arg in
    f) # Specify sample name (e.g. clone_celltype_condition_rep).
        SAMPLE=${OPTARG};; 
    d) # Specify directory containing gun-zipped fastqs.
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

module load ucsctools
module load bowtie2
module load sambamba
module load samtools

start="$(date)"

echo ""
echo "+--------------------------------------------------------------+"
echo "|                          QUICK-CHIP                          | "
echo "|   Fastq -> bigwigs for a quick look at your ChIP-seq data"   |
echo "+--------------------------------------------------------------+"
echo " Run started: " "$start"
echo ""

# Determine bt2 directory:
if [ $GENOME == "mm39" ]; then
   BT2DIR="/stopgap/databank/igenomes/Mus_musculus/UCSC/mm39/Sequence/Bowtie2Index"
elif [ $GENOME == "hg38" ]; then
   BT2DIR="/stopgap/databank/igenomes/Homo_sapiens/UCSC/hg38/Sequence/Bowtie2Index"
else
  echo "Incorrect genome entered. Choose either mm39 or hg38."
fi

# Step 1: Align using Bowtie2
echo " Step 1: Aligning using Bowtie2..."
bowtie2 -x ${BT2DIR}/genome -1 ${DATA}/${SAMPLE}_R1.fastq.gz  -2 $DATA/${SAMPLE}_R2.fastq.gz -S ${SAMPLE}.sam
echo " ...complete"

# Step 2: Sam to Bam conversion
echo " Step 2: Sam to Bam conversion"
samtools view -S -b ${SAMPLE}.sam > ${SAMPLE}.bam
echo " ...complete"

# Step 3: sort bamfile by genomic coordinate
echo " Step 3: Sorting bamfile"
sambamba sort -o ${SAMPLE}_sorted.bam ${SAMPLE}.bam
echo " ...complete"

# Step 4: remove duplicates
echo " Step 4: Removing duplicates"
sambamba markdup -r ${SAMPLE}_sorted.bam ${SAMPLE}_sorted_rmdup.bam
echo " ...complete"

# Step 5: index bam
echo " Step 5: Indexing bamfile"
sambamba index ${SAMPLE}_sorted_rmdup.bam ${SAMPLE}.bai
echo " ...complete"

# Step 6: creating a bigwig using DeepTools 
echo " Step 6: Creating bigwig"
bamCoverage -b ${SAMPLE}_sorted_rmdup.bam -o ${SAMPLE}.bw
echo " ...complete" 

# Step 7: copy bigwigs to datashare folder to view on ucsc genome browsed
cp ${SAMPLE}.bw /datashare/${public_dir}
echo ""
echo "Copy + paste link into UCSC genome browser:"
echo "track name=${SAMPLE} bigDataUrl=http://sara.molbiol.ox.ac.uk/public/${public_dir}/${SAMPLE}.bw type=bigWig color=0,76,153 dataViewScaling="Use vertical viewing range setting" visibility=full"
echo ""

echo "Cleaning up..."
rm ${SAMPLE}*.bam
rm ${SAMPLE}*.sam
rm ${SAMPLE}*.bai

end="$(date)"
echo ""
echo "Run complete:" "$end"
echo "+--------------------------------------------------------------+"
echo ""

