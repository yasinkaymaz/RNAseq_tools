#!/bin/bash

dataname=$(basename `pwd`)

for type in genes isoforms;
do
  for norm in Count TPM;
  do
    echo $type $norm
    cut -f1 .tmp.file.sub00_dir/rsem_quant/rsem_"${norm}"_table_"${type}".txt > table.txt

    for table in `ls -1 .tmp.file.sub*/rsem_quant/rsem_"${norm}"_table_"${type}".txt`;
    do
      echo "$table";
      cut -f2- $table > tmp.table.values;
      paste -d "\t" table.txt tmp.table.values > Table.txt;
      rm table.txt;
      mv Table.txt table.txt;
      rm tmp.table.values;
    done
    mv table.txt "$dataname"_rsem_"${type}"_"${norm}"_matrix.txt

  done
done
