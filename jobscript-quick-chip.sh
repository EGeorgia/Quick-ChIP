#!/bin/bash
#SBATCH --partition=batch
#SBATCH --job-name=WT-ES
#SBATCH --ntasks=1
#SBATCH --mem=20G
#SBATCH --output=%j_%x.out
#SBATCH --error=%j_%x.err
#SBATCH --mail-user=emily.georgiades@imm.ox.ac.uk
#SBATCH --mail-type=end,fail


cd /stopgap/fgenomics/egeorgia/quick-chip/

bash quick-chip_withflags.sh -f 2WT_E14_rad21_rep2 -d ../fastqs -g mm39 -p egeorgia/ChIP-seq/mm39/

