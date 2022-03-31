#!/bin/bash

# Specify parameters:
usage() { echo -e "
+-------------------------------------------------------+
|                      QUICK-CHIP                       |
|          Fastq -> bigwigs for ChIP-seq data           |
|             Emily Georgiades, August 2021             |
+-------------------------------------------------------+
Notes: sample name should be consistent with fastq naming.\n
Use following flags:" && grep " .)\ #" $0; exit 0; }
[ $# -eq 0 ] && usage
while getopts ":f:d:r:g:t:p:" arg; do
  case $arg in
    r) # Specify whether reads are 'single' or 'paired'
    READS=${OPTARG};;
    g) # Specify genome build (mm39, mm39-R2, mm39-R1R2 or hg38), include xxx (/xxx.1.bt2).
	  GENOME=${OPTARG};;
    t) # Should adapters be trimmed? (no/chip/chipment).
    TRIM=${OPTARG};;
    p) # Give path to public directory where bigwigs will be saved (not including /datashare/).
	  public_dir=${OPTARG};;
    h) # Display help.
      usage
      exit 0
      ;;
  esac
done


INPUT_FASTQS="./paths_to_fastqs.txt"

start="$(date)"

echo ""
echo "+--------------------------------------------------------------+"
echo "|                        QUICK-CHIP                            |"
echo "|          Run started:  "$start"                              |"
echo "+--------------------------------------------------------------+"
echo ""
echo "Loaded modules:"
module list
echo ""

# Determine which bt2 directory to use:
if [ $GENOME == "mm39" ]; then
   BT2DIR="/t1-data/databank/igenomes/Mus_musculus/UCSC/mm39/Sequence/Bowtie2Index/genome"
elif [ $GENOME == "mm39-R2" ]; then 
   BT2DIR="/t1-data/project/fgenomics/egeorgia/Data/Bowtie2/Bowtie2_mm39-AL2R2chrX/mm39-AL2R2chrX"
elif [ $GENOME == "mm39-R1R2" ]; then
   BT2DIR="/t1-data/project/fgenomics/egeorgia/Data/Bowtie2/Bowtie2_mm39-R1R2chrX/mm39-R1R2chrX"
elif [ $GENOME == "hg38" ]; then
   BT2DIR="/t1-data/databank/igenomes/Homo_sapiens/UCSC/hg38/Sequence/Bowtie2Index/genome"
else
  echo "Incorrect genome entered, choose either mm39 or hg38."
fi

# Option prelim step: adapter trimming
if [ $TRIM == "chip" ]; then
  ADAPTER="GATCGGAAGAGCACACGT"
elif [ $TRIM == "chipment" ]; then
  ADAPTER="CTGTCTCTTATACACATCT"
elif [ $TRIM == "no" ]; then
  echo "Skipping adapter trimming"
else
  echo "Specify either chip, chipment or none in -t"
fi


# Loop through each sample and process:
for file in ${INPUT_FASTQS}
do
    while IFS=$'\t' read -r sampleName DIR
    do 
        # Unload all modules for a clean start (would be better in snakemake, this is a workaround)
        module purge

        # Load required modules
        module load cutadapt
        module load ucsctools
        module load bowtie2
        module load sambamba
        module load samtools
        
        SAMPLE="${sampleName}"
        DATA="${DIR}"
        echo "Processing sample: ${SAMPLE}"
        echo ""
        echo "Fastqs located here: ${DATA}"
        echo ""

        # NEBNext® Ultra™ and NEBNext® Ultra™ II DNA Library Prep Kits for Illumina® (GATCGGAAGAGCACACGT)
        # Truseq Illumina, for ChIPmentation/ATAC (CTGTCTCTTATACACATCT)

        # Step 1: Align single ot paired end reads using Bowtie2

        # For single-end reads:
        if [ $READS == "single" ]; then
          echo " Step 1: Processing single-end reads"
          if [ $TRIM != "no" ]; then
            echo "Preliminary step: adapter trimming of single-ended reads"
            cutadapt -a ${ADAPTER} ${DATA}/${SAMPLE}.fastq.gz | cutadapt -m 18 -o ${DATA}/${SAMPLE}_trimmed.fastq.gz -
            echo "Aligning trimmed reads with bowtie2"
            bowtie2 -x ${BT2DIR} -U ${DATA}/${SAMPLE}_trimmed.fastq.gz -S ${SAMPLE}.sam
          else
            echo "Proceeding without adapter trimming. Aligning reads with Bowtie2"
            bowtie2 -x ${BT2DIR} -U ${DATA}/${SAMPLE}.fastq.gz -S ${SAMPLE}.sam
          fi

        # For paired-end reads:
        elif [ $READS == "paired" ]; then
          echo " Step 1: Processing paired-end reads"
          if [ $TRIM != "no" ]; then
            echo "Preliminary step: adapter trimming of paired-ended reads"
            cutadapt -a ${ADAPTER} ${DATA}/${SAMPLE}_R1.fastq.gz | cutadapt -m 18 -o ${DATA}/${SAMPLE}_R1_trimmed.fastq.gz -
            echo "READ1 adapters trimmed."
            cutadapt -a ${ADAPTER} ${DATA}/${SAMPLE}_R2.fastq.gz | cutadapt -m 18 -o ${DATA}/${SAMPLE}_R2_trimmed.fastq.gz -
            echo "READ2 adapters trimmed."
          else
            echo "Proceeding without adapter trimming. Aligning paired-end reads using Bowtie2"
            bowtie2 -x ${BT2DIR} -1  ${DATA}/${SAMPLE}_R1.fastq.gz  -2 ${DATA}/${SAMPLE}_R2.fastq.gz -S ${SAMPLE}.sam
          fi
        else
          echo "Paired or single-end reads must be specified."
        fi

        # Step 2: Sam to Bam conversion
        echo " Step 2: Sam to Bam conversion"
        if ! samtools view -S -b ${SAMPLE}.sam > ${SAMPLE}.bam ; then
            echo "samtools view returned an error"
            exit 1
        fi

        # Step 3: sort bamfile by genomic coordinate
        echo " Step 3: Sorting bamfile"
        if ! sambamba sort -o ${SAMPLE}_sorted.bam ${SAMPLE}.bam ; then
            echo "sambamba sort returned an error"
            exit 1
        fi

        # Step 4: remove duplicates
        echo " Step 4: Removing duplicates"
        if ! sambamba markdup -r ${SAMPLE}_sorted.bam ${SAMPLE}_sorted_rmdup.bam ; then
           echo "sambamba markdup returned an error"
           exit 1
        fi

        # Step 5: index bam
        echo " Step 5: Indexing bamfile"
        if ! sambamba index ${SAMPLE}_sorted_rmdup.bam ${SAMPLE}_sorted_rmdup.bam.bai ; then
            echo "sambamba index returned an error"
            exit 1
        fi

        # Step 6: creating a bigwig using DeepTools
        module unload python-base
        module load deeptools
        echo " Step 6: Creating bigwig in correct format for lanceotron"
        if ! bamCoverage -b ${SAMPLE}_sorted_rmdup.bam -o ${SAMPLE}_lanceotron.bw --extendReads -bs 1 --normalizeUsing RPKM; then
            echo "bamcoverage returned an error"
            exit 1
        fi

        # Step 7: copy bigwigs to datashare folder to view on ucsc genome browsed
        cp ${SAMPLE}.bw /datashare/${public_dir}
        echo ""
        echo "Copy + paste link into UCSC genome browser:"
        echo "http://sara.molbiol.ox.ac.uk/public/${public_dir}/${SAMPLE}.bw"
        echo ""
    done
done < "${INPUT_FASTQS}"

end="$(date)"
echo ""
echo "Run complete:" "$end"
echo "+--------------------------------------------------------------+"
echo "################################################################"
echo ""
