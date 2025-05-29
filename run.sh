#!/bin/bash

# apptainer run \
# 	bidseq_latest.sif \
# 	--mysnake pseudoU-BIDseq/Snakefile \
# 	--until join_pairend_reads -j 10

conda activate snake
snakemake --snakefile pseudoU-BIDseq/Snakefile \
	--profile bid_cluster \
	--configfile data.yaml -nq
