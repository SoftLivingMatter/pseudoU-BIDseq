#!/bin/bash

# apptainer run \
# 	bidseq_latest.sif \
# 	--mysnake pseudoU-BIDseq/Snakefile \
# 	--until join_pairend_reads -j 10

module load anaconda3/2024.6
conda activate snake
snakemake --snakefile Snakefile \
	--profile bid_cluster \
	--configfile for_aya_18S.yaml $@
