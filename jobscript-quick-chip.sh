#!/bin/bash
#SBATCH --partition=batch
#SBATCH --job-name=quick-chip
#SBATCH --ntasks=1
#SBATCH --mem=10G
#SBATCH --time=00-12:00:00
#SBATCH --output=%j_%x.out
#SBATCH --error=%j_%x.err
#SBATCH --mail-user=email@address
#SBATCH --mail-type=end,fail


cd /working-dir/

bash quick-chip_withflags.sh -r paired/single -t adapter-trimming -t trimming -g genome-build -p path/to/public-dir
