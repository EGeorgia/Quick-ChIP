# :hourglass_flowing_sand: Quick-ChIP
#### Quick and easy analysis of ChIP-seq data on stopgap for visualisation using the [UCSC genome browser.](https://genome.ucsc.edu/)

_Emily Georgiades, Hughes Lab_   
_July 2021_   

![Screenshot 2021-08-06 at 09 35 10](https://user-images.githubusercontent.com/48098922/128482191-ed9adb74-5e76-4348-8d85-cd7d158eedaa.png)
***

#### 1. Create a directory containing:  
   * [yy-mm-dd-experiment-setup.md](./yy-mm-dd-experiment-setup.md): file containing info on experimental design and set-up
   * [jobscript-quick-chip.sh](./jobscript-quick-chip.sh)

#### 2. Create a public directory where bigwigs will be copied to.

#### 2. Edit flags in [jobscript](./jobscript-quick-chip.sh):  
```bash quick-chip_withflags.sh -f sample_name -d fastq_dir -g genome -p public_dir```

__-f__   Specify sample name (e.g. clone_celltype_condition_rep).  
__-d__   Specify directory containing gun-zipped fastqs.  
__-g__   Specify genome build (mm39 or hg38).  
__-p__   Give path to public directory where bigwigs will be saved (excluding /datashare/).  
__-h__   Display help.  

*** 

To run the script:  
``` $ sbatch jobscript-quick-chip.sh ```

To check that it's running:  
``` $ squeue | grep username ```

To check progress of run (where xxx is jobID):   
``` $ less xxx_quick-chip.out ```

To cancel the run (where xxx is jobID):  
``` $ scancel xxx ```
