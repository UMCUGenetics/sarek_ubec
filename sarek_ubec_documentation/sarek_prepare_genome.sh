#################
### Input and output
#################

#fasta=/path/to/genome
#fasta_out=/path/to/out

fasta=/hpc/ubec/resources/tools/rnaseq-nf/genome_files/GRCh38_chr1_M/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
fasta_out=/hpc/ubec/resources/tools/rnaseq-nf/genome_files/GRCh38_chr1_M/GRCh38_ncbi_chronly.fa

ref_dir=`dirname $fasta_out`

# set chromosomes to include
chr=$(seq 1 1 22)" X Y M"

# set prefix used in input fasta and to be used in output fasta
chr_prefix="chr"
#input_chr_prefix="chr"
#output_chr_prefix="chr"

######################################
### Make subset of genome if necessary
######################################


# Create fasta index if not existing already
if [[ ! -f ${fasta}.fai ]]; then
	samtools faidx $fasta
fi

# create chr string based on chr to include
chr_string=""
for c in $chr; do
	if [[ "$chr_string" != "" ]]; then
		chr_string=${chr_string}" "
	fi
	chr_string=${chr_string}${chr_prefix}${c}
done

# make subset of fasta and crate index
samtools faidx ${fasta} ${chr_string} > ${fasta_out}
samtools faidx $fasta_out

#################
### Split per chr
#################

#https://crashcourse.housegordon.org/split-fasta-files.html

chr_files_dir=${ref_dir}/chr_files
mkdir ${chr_files_dir}

# split based on >chr entry
csplit -s -z ${fasta_out} '/>/' '{*}'
# move resulting files using >chr entry for filename
for i in xx* ; do
	n=$(sed 's/>// ; s/ .*// ; 1q' "${$i")
	mv "$i" ${chr_files_dir}/"${n}.fa"
done

######################
### Create BWA indexes
######################

bwa index ${fasta_out}

######################
### Create .dict file (and make extra copy in case of naming issues)
###################### 

#GATK requires the naming to be <fasta basename>.dict, despite what's defined in config... 
java -jar picard.jar CreateSequenceDictionary REFERENCE=${fasta_out} OUTPUT=${fasta_out/\.fa/\.dict}

######################
### Create .faidx file
######################

samtools faidx $fasta_out

######################
### Create .interval_list
######################

#awk '{ print $1"\t1\t"$2"\t+\t."}' ${fasta_out}.fai | cat ${fasta_out}.dict - > ${fasta_out}.interval_list
#mv ${fasta_out}.interval_list ${fasta_out/fa/interval_list}
awk '{ print $1"\t1\t"$2"\t+\t."}' ${fasta_out}.fai | cat ${fasta_out}.dict - > ${fasta_out/\.fa/\.interval_list}

##################################################################
### Create .bed (can also be used for interval list, created for completeness
##################################################################

awk -v FS='\t' -v OFS='\t' '{ print \$1, \"0\", \$2 }' ${fasta_out}.fai > ${fasta_out}.bed

######################
### Create .len (needs to have no chr prefix in first and chr prefix in second column?)
######################

if [[ "$chr_prefix" == "" ]]; then
	awk '{print $1"\tchr"$1"\t"$2'} ${fasta_out}.fai > ${fasta_out/\.fa/\.len}
else
	awk '{gsub("chr", "", $1); print $1"\tchr"$1"\t"$2'} ${fasta_out}.fai > ${fasta_out/\.fa/\.len}
fi


