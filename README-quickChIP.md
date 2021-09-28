+------------------------------------------------------------------------------------+
|          QUICK-ChIP Analysis Set-up Intructions                                    |
+------------------------------------------------------------------------------------+
| Emily Georgiades, Hughes Lab                                                       |
| August 2021                                                                        |
+------------------------------------------------------------------------------------+

This is for a quick analysis using stopgap and visualisation  
using UCSC genome browser.

Step 1: Create a directory containing:
- yy-mm-dd-experiment-setup.md: file containing info on experimental design and set-up.
- jobscript-quick-chip.sh

Step 2: Create a public directory where bigwigs will be copied to.

Step 3: Ensure fastqs are gunzipped and named as follows:
Paired-end reads:
- sample_name_R1.fastq.gz
- sample_name_R2.fastq.gz
Single-end reads:
- sample_name.fastq.gz

Step 4: Edit flags in jobscript-quick-chip.sh:
bash quick-chip_withflags.sh -f sample_name -r single -d fastq_dir -g genome -p public_dir

-f  Specify sample_name (e.g. clone_celltype_condition_rep).
-r  Specify whether reads are 'single' or 'paired'.
-d  Specify directory containing gun-zipped fastqs.
-g  Specify genome build (mm39 or hg38).
-p  Give path to public directory where bigwigs will be saved (excluding /datashare/).
-h  Display help.

Notes:
Preliminary step is to trim adapters, specifically for NEBNext® Ultra™ / NEBNext® Ultra™ II DNA Library Prep Kits for Illumina®.
Adapter sequence: GAT CGG AAG AGC ACA CGT

+------------------------------------------------------------------------------------+
To run the script:
$ sbatch quick-chip.sh

To check that it's running:
$ squeue | grep nroberts

To check progress of run (where xxx is jobID):
$ less xxx_quick-chip.out 

To cancel the run (where xxx is jobID):
$ scancel xxx
+------------------------------------------------------------------------------------+  


