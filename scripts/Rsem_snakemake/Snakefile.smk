import pandas as pd
import os
import glob
SNAKEMAKE_DIR = os.path.dirname(workflow.snakefile)

#configfile: "%s/config.json" % SNAKEMAKE_DIR
configfile: "config.json"
RUN_INFO = pd.read_table(config["sra_run_info"])
SAMPLES = RUN_INFO["BioSample"].tolist()
RUNS = RUN_INFO["Run"].tolist()
organism=config["organism"]
#print(config["organism"])
#print(config)
LibraryLayouts = RUN_INFO["LibraryLayout"].tolist()


def _get_run_by_sample_id(wildcards):
    pass

if LibraryLayouts[0] == "SINGLE":
    fqcount=['']
    Pairness=''
    trimPaired=''
else:
    fqcount=['_1','_2']
    #FQcount=['_R1','_R2']
    Pairness='--paired-end'
    trimPaired='--paired'

localrules: all, rsem_index, get_fastq_files_from_dir, prepare_reads, rsem_quant_sample, create_rsem_table

rule all:
    input: "rsem_quant/rsem_TPM_table_genes.txt"


rule rsem_index:
    input:
        fa=config['rsem_rules']['reference'],
        gtf=config['rsem_rules']['gtf']
    output:
        str(config['rsem_rules']['idx_prefix']+".ti")
    params:
        threads_n=4,
        star_path=config['rsem_rules']['star_path'],
        idx_prefix=config['rsem_rules']['idx_prefix']
    threads: 4
    shell:
        """
        rsem-prepare-reference -p {params.threads_n} --gtf {input.gtf} --star --star-path {params.star_path} {input.fa} {params.idx_prefix}
        """


rule get_fastq_files_from_dir:
    output:
        fqs=temp(['fastq/runs/{sample}/{run}'+mate+'.fastq' for mate in fqcount])
    params:
        threads_n=1,
        mem_lim=6000,
        sra_tmp_dirs="fastq/sraLogs/{sample}_{run}",
        run_prefix=lambda wildcards: wildcards.run[:6],
        sra_prefix=lambda wildcards: wildcards.run[:3]
    shell:
        """
        cp ../SRA/{wildcards.run}*.fastq fastq/runs/{wildcards.sample}/
        """


rule prepare_reads:
    input:
        runfqs= [['fastq/runs/'+SAMPLES[i]+'/'+RUNS[i]+mate+'.fastq' for mate in fqcount] for i in range(len(SAMPLES))]
    output:
        mergedfqs=temp(['fastq/merged/{sample}'+mate+'.fastq' for mate in fqcount]),
        trimmedfqs=['fastq/trimmedfqs/{sample}'+mate+'_val'+mate+'.fq.gz' for mate in fqcount]
    params:
        prefix="fastq/merged/{sample}",
        liblayout=LibraryLayouts[0],
        dir="fastq/runs/{sample}/",
        toolDir=config["scRNAtoolDir"],
        Pairness=trimPaired
    log:
        trimlog="fastq/trimmingLogs/{sample}.trim_galore.log"
    shell:
        """
        bash {params.toolDir}/scripts/kallisto_snakemake/merge_run.fastqs.sh {params.liblayout} `pwd`/{params.dir} `pwd`/{params.prefix}
        (trim_galore --gzip --length 15 {params.Pairness} --no_report_file -o `dirname {output.trimmedfqs[0]}` {output.mergedfqs}) 2> {log.trimlog}
        """



rule rsem_quant_sample:
    input:
        reads=['fastq/trimmedfqs/{sample}'+str(mate)+'_val'+mate+'.fq.gz' for mate in fqcount]
    output:
        "rsem_quant/{sample}/{sample}.genes.results",
        "rsem_quant/{sample}/{sample}.isoforms.results"
    params:
        output_prefix = "rsem_quant/{sample}/{sample}",
        sampleID = "{sample}",
        Pairness= Pairness,
        threads_n=2,
        star_path=config['rsem_rules']['star_path'],
        index=config['rsem_rules']['idx_prefix']
    log:
        "rsem_quant/rsem_logs/{sample}.log"
    threads: 2
    shell:
        """
        mkdir rsem_quant/{wildcards.sample}.temp/
        (rsem-calculate-expression -p {params.threads_n} {params.Pairness} \
        --star --star-path {params.star_path} \
        --strandedness 'none' \
        --append-names \
        --no-bam-output \
        --star-gzipped-read-file \
        --single-cell-prior \
        {input.reads} \
        --temporary-folder rsem_quant/{wildcards.sample}.temp/ \
        {params.index} {params.output_prefix}) 2> {log}

        rm -r rsem_quant/{wildcards.sample}/{wildcards.sample}.stat
        """


rule create_rsem_table:
    input:
        geneTable=expand(str("rsem_quant/{sample}/{sample}"+".genes.results"), sample=set(SAMPLES)),
        isoTable=expand(str("rsem_quant/{sample}/{sample}"+".isoforms.results"), sample=set(SAMPLES))
    output:
        "rsem_quant/rsem_TPM_table_genes.txt",
        "rsem_quant/rsem_Count_table_isoforms.txt"
    threads: 1
    params:
        toolDir=config['scRNAtoolDir']
    shell:
        """
        perl {params.toolDir}/utils/merge_Rsem-outputs_single_table_TPM.pl {input.geneTable} > rsem_quant/rsem_TPM_table_genes.txt
        perl {params.toolDir}/utils/merge_Rsem-outputs_single_table_Counts.pl {input.geneTable} > rsem_quant/rsem_Count_table_genes.txt
        perl {params.toolDir}/utils/merge_Rsem-outputs_single_table_TPM.pl {input.isoTable} > rsem_quant/rsem_TPM_table_isoforms.txt
        perl {params.toolDir}/utils/merge_Rsem-outputs_single_table_Counts.pl {input.isoTable} > rsem_quant/rsem_Count_table_isoforms.txt
        """
