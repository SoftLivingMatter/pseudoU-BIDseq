#!/bin/bash

# apptainer run \
# 	bidseq_latest.sif \
# 	--mysnake pseudoU-BIDseq/Snakefile \
# 	--until join_pairend_reads -j 10

module load anaconda3/2024.6
conda activate snake

snakemake Snakefile \
	--profile bid_cluster \
	--configfile config.yaml $@
