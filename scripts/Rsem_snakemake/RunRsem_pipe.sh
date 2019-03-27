#!/bin/bash

SRPid=$1
SnakemakeFile=$2
dataname=$(basename `pwd`)
runtype=$3
bash ~/codes/BI-compbio/scripts/SRA_prep.sh $SRPid $dataname

. /n/home13/yasinkaymaz/miniconda3/etc/profile.d/conda.sh
conda activate scRNAseqPipe
source new-modules.sh
module load R/3.4.2-fasrc01
module load gcc/7.1.0-fasrc01
module purge
#module load rsem/1.2.29-fasrc02 ---> DON't load. needs to be compiled.
module load centos6/0.0.1-fasrc01
module load glib/2.32.4-fasrc01
export PATH=/n/home13/yasinkaymaz/biotools/RSEM-1.3.0/bin:$PATH


InputSRAinfoFILE="$dataname"_SRA_info.txt

cores=6


for i in `tail -n+2 "${InputSRAinfoFILE}" |cut -f2|sort|uniq`;do echo $i;done > tmp.file
split -d -l 50 tmp.file .tmp.file.sub

for tmpfile in `ls -1a|grep .tmp.file.sub|grep -v dir`;
do
	if [ ! -d "$tmpfile"_dir ]; then mkdir "$tmpfile"_dir; fi
	head -1 "${InputSRAinfoFILE}" > "$tmpfile"_dir/"${InputSRAinfoFILE}${tmpfile}";
	mv $tmpfile "$tmpfile"_dir/

	cd "$tmpfile"_dir/

	for sample in `cat "$tmpfile"`;
	do
		grep -w "$sample" ../"${InputSRAinfoFILE}" >> "${InputSRAinfoFILE}${tmpfile}";
	done

	cat ~/codes/BI-compbio/scripts/snakemakeConfigs/config.json | sed 's/\bINPUTSRAINFO\b/'"${InputSRAinfoFILE}${tmpfile}"'/g' > ./config.json
	if [ ! -d slurmLogs ]; then mkdir slurmLogs; fi

	checkFiles=`snakemake -n -s ${SnakemakeFile}`

	if [ "$checkFiles" == "Nothing to be done." ];
	then
		echo "Skipping ${tmpfile} . ${checkFiles}";
	else
		echo "Running ${tmpfile} ...";

		snakemake --unlock --snakefile ${SnakemakeFile}

		if [ "$runtype" == "local" ];
		then
			snakemake -r --cores $cores -p \
			    --local-cores $cores \
			    --latency-wait 3 \
			    --use-conda \
			    --keep-going \
			    --timestamp \
			    --max-jobs-per-second 2 \
					--rerun-incomplete \
			    --cluster-config ~/codes/BI-compbio/scripts/snakemakeConfigs/cluster.odyssey.json \
			    --cluster 'sbatch -p {cluster.queue} -n {cluster.n} -t {cluster.time} --mem={cluster.memory} -e slurmLogs/err.%j.out -o slurmLogs/std.%j.out' \
			    --snakefile ${SnakemakeFile}
		else
			sbatch -p general \
			-n ${cores} \
			--mem 24000 \
			-t 6-0:00 \
			-e err.%j.txt \
			-o out.%j.txt \
			snakemake -r --cores $cores -p \
			    --local-cores $cores \
			    --latency-wait 36000 \
			    --use-conda \
			    --keep-going \
			    --timestamp \
			    --max-jobs-per-second 8 \
					--rerun-incomplete \
			    --cluster-config ~/codes/BI-compbio/scripts/snakemakeConfigs/cluster.odyssey.json \
			    --cluster 'sbatch -p {cluster.queue} -n {cluster.n} -t {cluster.time} --mem={cluster.memory} -e slurmLogs/err.%j.out -o slurmLogs/std.%j.out' \
			    --snakefile ${SnakemakeFile}
		fi



	fi

	sleep 3;
	cd ../

done

#How to run this:
#First create 'SRA' folder in the running directory && soft link all SRR*.fastq files into it.
#mkdir SRA; ln -s ~/LabSpace/SRAdata/mouse/SRP126648/*.fastq ./;

#bash ~/codes/BI-compbio/scripts/Rsem_snakemake/RunRsem_pipe.sh SRPid ~/codes/BI-compbio/scripts/Rsem_snakemake/Snakefile.smk runtype['local','cluster']
