# :hourglass_flowing_sand: Quick-ChIP
#### Quick and easy analysis of ChIP-seq data on stopgap for visualisation using the [UCSC genome browser.](https://genome.ucsc.edu/)

Emily Georgiades, Hughes Lab, July 2021.  
  

![Screenshot 2021-08-06 at 09 35 10](https://user-images.githubusercontent.com/48098922/128482191-ed9adb74-5e76-4348-8d85-cd7d158eedaa.png)
***

### Steps for setup:

#### 1. Create a directory containing:  
   * [yy-mm-dd-experiment-setup.md](./yy-mm-dd-experiment-setup.md): file containing info on experimental design and set-up
   * [jobscript-quick-chip.sh](./jobscript-quick-chip.sh)

#### 2. Create a public directory where bigwigs will be copied to.

#### 3. Ensure fastqs are gunzipped and named as follows:  
Paired-end reads:   
```sample_name_R1.fastq.gz```  
```sample_name_R2.fastq.gz```

Single-end reads:   
```sample_name.fastq.gz```  

#### 4. Edit flags in [jobscript](./jobscript-quick-chip.sh):  
```bash quick-chip_withflags.sh -f sample_name -r paired -d fastq_dir -g genome -p public_dir```

__-f__&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Specify sample_name (e.g. clone_celltype_condition_rep).  
__-r__&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Specify whether reads are 'single' or 'paired'.  
__-d__&nbsp;&nbsp;&nbsp;&nbsp;Specify directory containing gun-zipped fastqs.  
__-g__&nbsp;&nbsp;&nbsp;&nbsp;Specify genome build (mm39, mm39-R2, mm39-R1R2 or hg38).  
__-t__&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Specify if/which adapters should be trimmed? (no/chip/chipment).  
__-p__&nbsp;&nbsp;&nbsp;&nbsp;Give path to public directory where bigwigs will be saved (excluding /datashare/).  
__-h__&nbsp;&nbsp;&nbsp;&nbsp;Display help.  

#### :pencil:&nbsp;&nbsp;Notes:
Preliminary step is to trim adapters, specifically for NEBNext® Ultra™ / NEBNext® Ultra™ II DNA Library Prep Kits for Illumina®.   
Adapter sequence: GAT CGG AAG AGC ACA CGT

*** 

To run the script:  
``` $ sbatch jobscript-quick-chip.sh ```

To check that it's running:  
``` $ squeue | grep username ```

To check progress of run (where xxx is jobID):   
``` $ less xxx_quick-chip.out ```

To cancel the run (where xxx is jobID):  
``` $ scancel xxx ```
