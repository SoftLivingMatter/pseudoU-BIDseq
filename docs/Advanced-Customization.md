---
title: Advanced Customization
nav_exclude: false
nav_order: 4
---

<!-- prettier-ignore-start -->
# Advanced Customization
{: .fs-9 }
<!-- prettier-ignore-end -->

## Pair-end mode

According to the fragment size of BID-seq libraries, SE100 or SE150 sequencing mode is sufficient for most of the RNA fragments.
To reduce cost, you do not need to run pair-end sequencing for most of the samples.
But if you have a longer insert fragment size, or want to improve sequencing quality by PE mode, this pipeline also supports analyzing data from PE mode.

And the setup is as simple as adding a single line into the YAML configure file.

```yaml
samples:
  mESCWT-rep1-input:
    data:
      - R1: ./test/IP16_R1.fastq.gz
        R2: ./test/IP16_R2.fastq.gz
```

`R2: ./test/IP16_R2.fastq.gz` is added under the data tag.

{: .note }
Read 2 file is labeled with an `R2` tag, and it is in the same indent as the `R1` tag. There is no hyphen symbol before the `R2` tag, because R2 and R1 are in pairs.

## Multiple sequencing runs

If you sequenced the same library in multiple sequencing flowcells or added more reads for your sample, you do not need to combine the data before running this pipeline.
You can add multiple runs under the data tag for one sample. When you start the pipeline, it will combine the data for this sample automatically.

```yaml
samples:
  mESCWT-rep1-input:
    data:
      - R1: ./test/IP16_sequencing_run1.fastq.gz
      - R1: ./test/IP16_sequencing_run2.fastq.gz
      - R1: ./test/IP16_sequencing_run2.fastq.gz
```

{: .note }
Sequencing data is combined after read alignment, rather than at the first step of the analysis. This strategy can save computation resources and energy. For example, sometimes you run the sequencing for your libraries but found that the data is not sufficient after the analysis.
You then add extra sequencing data for this library. In this pipeline, only newly generated data need to be aligned.

## Reverse strands

If the libraries were prepared by reverse stranded strategy, such as cDNA ligation or Stranded RNA-Seq Kit, you can set `forward_stranded` parameter as `false`.
The default setting is true.

```yaml
forward_stranded: false
```

(default `true`)

## Speed up alignment step

Mapping reads into `genes` reference is the time limiting step in this pipeline. Very strigent parameters were used to increase the sensitivity of reads with multiple gaps.
There are &Psi condense regions in the ribosome, and BID-seq treatment would created condense gaps within one read.
If these reads fail to align into rRNA sequence, the quantification of rRNA modification would be affected, and might also create false positives in the genome.

However, the strigent parameters would slow down the alignment step. If you are not intested in the stoichiometry of rRNA site, you can set `speedy_mapping` parameter to speed up the analysis.

```yaml
speedy_mapping: true
```

(default: `false`)

## Use pre-analyzed bam file for &Psi; sites detection only

```yaml
samples:
  mESCWT-rep1-treated:
    bam:
      gene: A1.gene.bam
      genome: A1.genome.bam
  mESCKO-rep1-treated:
    bam:
      gene: B1.gene.bam
      genome: B1.genome.bam
```

## Customized adapter / inline barcode / trimming tails

You can customize the adapter sequencing if you are not using the adapter (*NNNNN*AGATCGGAAGAGCACACGTCT) provided by the protocol.

By default, only 5 N are added on the 3' adapter, which is used as a UMI (Unique Molecular Identifier).
But it is also possible to add an inline barcode as the one used in _Nature Biotech._ [paper](https://www.nature.com/articles/s41587-022-01505-w#Sec12) (_NNNNN_<u>ATCACG</u>AGATCGGAAGAGCACACGTCT).
Moreover, you can also specify the 5' UMI in the barcode setting.

There are two ways to specify the inline barcode and 5' UMI.

- You can apply the global setting for all the samples in the configure file by adding:

```yaml
barcode: NNNNNXXX-XXXNNNNNATCACG
```

which means there is a 5nt of UMI (NNNNN) on 5' and 5nt of UMI (NNNNN) on 3' with an `ATCACG` inline barcode. Meanwhile, 3 bases (XXX) on both ends will be trimmed after removing the adapters.

If there is **no** 5' UMI, but with inline barcode. The setting scheme is as follows:

```yaml
barcode: NNNNNATCACG
```

- If only some of the libraries are with inline barcodes, while others are not, you can specify inline barcodes for each sample respectively. Leave it blank (default) means without an inline barcode.

```yaml
samples:
  mESCWT-rep1-input:
    data:
      - R1: ./test/IP16_sequencing_run1.fastq.gz
    barcode: NNNNN-NNNNNATCACG
```

## Share input samples among different groups

For **pre-filtering** &Psi sites, only deletion signal on treated samples are used. And the pre-filtering step works group by group. Note that `group` is the defined in the `yaml` file by yourself.

However, for **post-filtering** &Psi sites, input samples are also included for masking background noise and SNP sites. Input libraries are similar to RNA-seq libraries, thus samples from an unique source won't have big difference in genotype.
Even samples prepared from different condition, eg stress vs. control, can be combined are genotyping. To save sequencing cost, input libraries can be sequenced shallow and combined among groups.

If you want to do so, just add multiple group labels into the configure file as the example bellow.

```yaml
samples:
  mESCWT-rep1-input:
    data:
      - R1: ./test/IP16_R1.fastq.gz
    group:
      - mESC-WT
      - mESC-KO
```

Note that there is hyphen symbol before the group name, and one record in a one line. The group information in the input libraries won't have any effects on your results if your skip post-filtering step.

## Customized cutoff for pre-filtering

Not recommended
{: .label .label-red }

Add the following **whole** block into the configure file (`data.yaml` for example), and adjust the parameters.

```yaml
cutoff:
  min_match_prop: 0.8
  min_group_gap: 5
  min_group_depth: 10
  min_group_ratio: 0.01
  min_group_num: 1
```

- `min_match_prop`: STAR `outFilterMatchNminOverLread`
- `min_group_gap`: prefilter sites show >= x gaps in total among all samples in each group
- `min_group_depth`: prefilter sites show >= x sequencing coverage in total among all samples in each group
- `min_group_ratio`: prefilter sites show >= x deletion ratio among all samples in each group
- `min_group_num`: only analysis putative sites that show pass prefilter in >= x groups

## Post filter sites

Experimental
{: .label .label-red }

Add the following block to the data.yaml file to do post-filtering.

Note:

- There is an indent (space) before each parameter
- The filter includes the number itself. For example, `min_treated_depth: 20` will filter sites with more than and **equal to** 20 coverage.
- `min_passed_group: 1` means sites that pass filtering for **any** group will be retained.

```yaml
# optional
# calibration_curves: ./calibration_curves.tsv

# required
group_filter:
  combine_group_input: true
  min_passed_group: 1
  min_treated_depth: 20
  min_input_depth: 20
  min_treated_gap: 5
  min_treated_ratio: 0.02
  min_treated_fraction: 0.02
  min_fold_ratio: 2
  max_p_value: 0.0001
```

## Cache internal files to speed up

Add the following setting in the configure file to turn on `keep_internal` (default: false).

```yaml
keep_internal: true
```

Once internal files, including reference index and mapping bam files, are cached, you do not need to re-run some steps of the pipeline when you add more sequencing reads.

## Keep discarded reads for debugging purposes.

Add the following setting in the configure file to keep discarded reads.

```yaml
keep_discarded: true
```

Once this parameter is set as true (default: False), untrimmed, too-short, unmapped... reads will be saved.
_Most of the time, you do not need these files. Set it as `false` to save storage._
