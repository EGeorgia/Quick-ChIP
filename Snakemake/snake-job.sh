#!/bin/bash
#SBATCH --partition=batch
#SBATCH --job-name=snake-chip
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --mem=128G
#SBATCH --time=00-12:00:00
#SBATCH --output=%j_%x.out
#SBATCH --error=%j_%x.err
#SBATCH --mail-user=emily.georgiades@imm.ox.ac.uk
#SBATCH --mail-type=end,fail

cd /t1-data/project/fgenomics/egeorgia/Projects/02_ChIP-seq_analysis_tools/Quick-ChIP/Snakemake/ 

snakemake

