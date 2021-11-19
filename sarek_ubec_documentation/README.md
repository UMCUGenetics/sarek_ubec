# Sarek Installation and Documentation
Installation and setup documents for sarek pipeline. Also describes changes made to the standard sarek pipeline:
* Change ControlFREEC behavior to work on bam files instead of mpileup
* Add customVCF annotation functionality
* More robust handling of custom genome names and content (incl singuliarty images)
* Minor bugfixes/changes

## Introduction
Sarek is a pipeline built in Nextflow designed to detect variants on whole genome or targeted sequencing data. Sarek can also handle tumor/normal pairs…
More information can be found at: 
https://nf-co.re/sarek

## Installing & Setup

1. [Install Nextflow](#install-nextflow)
2. [Install Singularity](#install-singularity)
3. [Pull or Clone Sarek](#pull-or-clone-sarek)
4. [Get & configure resources](#get-and-configure-resources)
5. [Configure Nextflow](#configure-nextflow)
6. [Configure processes](#configure-processes)
7. [Modify code](#modify-code)
8. [Running the pipeline](#running-the-pipeline)
9. [Available tools](#available-tools)
10. [Workflow](#workflow)
11. [Test run](#test-run)

## Install Nextflow

Install the latest version of Nextfow (v20.40+ is needed for the latest v2.7.1 sarek release) using the [these instructions](https://www.nextflow.io/docs/latest/getstarted.html#installation)

Use this command to create the nextflow executable in the current folder, either copy the resulting nextflow binary to a folder in your path, add this folder to your path or call the pipeline using the full path to the Nextflow executable.

```
curl -fsSL get.nextflow.io | bash
```

## Install Singularity

Singularity is most likely already available on the HPC, if not follow [these instructions](https://sylabs.io/guides/3.5/admin-guide/)

## Pull or Clone Sarek

Use the following command to clone the Sarek pipeline in a sarek subfolder in the current working directory:

```
git clone https://github.com/nf-core/sarek.git
```

## Get and Configure resources

The default reference genome source for Sarek is [Illumina's iGenomes](https://support.illumina.com/sequencing/sequencing_software/igenome.html) which can alternatively be installed using [Amazon Web Services (AWS)](https://ewels.github.io/AWS-iGenomes)

It is also possible to use specific local genome resources.

### Downloading reference genome using AWS (GRCh37 example)

This way is the preferred way as the sarek igenomes.config is based on these genomes, when using custom genomes one has to modify the genomes.config file (found in the conf/ subfolder from sarek) accordingly.<br>

Download the reference genome of choice from https://ewels.github.io/AWS-iGenomes/<br><br>
For:<br>
Genome -> Source -> Build -> Type<br>
<br>
choose:<br>
Homo_Sapiens -> GATK -> GRCh37

Set up AWS for ad-hoc usage using guix

```
guixr environment --ad-hoc awscli
```

Change to target folder
```
cd /hpc/ubec/projects/sarek_v2.7.1_rollout/resources
```

Download selected genome (using the specified Sync command
```
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Homo_sapiens/GATK/GRCh37/ ./Homo_sapiens/GATK/GRCh37
```

The following commands can be used to download the relevant mouse genome data:
```
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Mus_musculus/Ensembl/GRCm38/Sequence/BWAIndex/ ./Mus_musculus/Ensembl/GRCm38/Sequence/BWAIndex/
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Mus_musculus/Ensembl/GRCm38/Sequence/Chromosomes/ ./Mus_musculus/Ensembl/GRCm38/Sequence/Chromosomes/
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Mus_musculus/Ensembl/GRCm38/Sequence/Length/ ./Mus_musculus/Ensembl/GRCm38/Sequence/Length/
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Mus_musculus/Ensembl/GRCm38/Sequence/WholeGenomeFasta/ ./Mus_musculus/Ensembl/GRCm38/Sequence/WholeGenomeFasta/
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Mus_musculus/Ensembl/GRCm38/MouseGenomeProject/ ./Mus_musculus/Ensembl/GRCm38/MouseGenomeProject/
aws s3 --no-sign-request --region eu-west-1 sync s3://ngi-igenomes/igenomes/Mus_musculus/Ensembl/GRCm38/Annotation/Control-FREEC ./Mus_musculus/Ensembl/GRCm38/Annotation/Control-FREEC/
```

### Downloading reference genome directly (GRCh37 and GRCm38 example)

Download the reference genome of choice for example from [https://support.illumina.com/sequencing/sequencing_software/igenome.html](https://support.illumina.com/sequencing/sequencing_software/igenome.html) and extract the downloaded archive

```
wget http://igenomes.illumina.com.s3-website-us-east-1.amazonaws.com/Homo_sapiens/Ensembl/GRCh37/Homo_sapiens_Ensembl_GRCh37.tar.gz
tar -xzvf Homo_sapiens_Ensembl_GRCh37.tar.gz
```

### Customize config files

In order to use the downloaded reference genome, the config files in the sarek pipeline must be adjusted

For example, to use and specify a custom config with the name 'umcu_grch37'<br>

#### Create custom config file

First we create a conf_custom subfolder in the sarek folder where the custom configs will be stored<br>

In order to use custom genome resources one must set the following parameters in the custom config file:
```
  //When using your own custom genomes, set igenomes_ignore to true in order for sarek to not use igenomes resources
  igenomes_ignore = true
  // Genome reference file paths, this is used in the genomes.config file
  genomes_base = '/hpc/ubec/resources/genomes/'
```

Below an example of a custom 'umcu_grch37.config' file, explanations are added in the config file<br>
```
//Profile config names for nf-core/configs
params {
  config_profile_description = 'UMCU HPC Cluster GRCh37 config.'
  config_profile_contact = 'Firstname Lastname'
  config_profile_url = 'https://www.umcutrecht.nl/'

  // When a reference is not yet downloaded it will be downloaded and saved
  save_reference = true

  //When using your own custom genomes, set igenomes_ignore to true in order for sarek to not use igenomes resources
  igenomes_ignore = true
  // illumina iGenomes reference file paths on UMCU HPC
  genomes_base = '/hpc/ubec/resources/genomes/'
  
  //in case you wish to use igenomes use this to set igenomes base folder (and disable the igenomes_ignore=true + genomes_base lines)
  //igenomes_base = '/hpc/ubec/resources/igenomes/'
  
  // genome used in this config
  genome = 'GRCh37'

  //keep mapped bams by default (preferable in case pipeline needs to be rerun)
  save_bam_mapped = true
  
  //increased mem usage due to step crashing otherwise
  markdup_java_options = '"-Xms16g -Xmx32g"' // Established values for markDuplicates memory consumption, see https://github.com/SciLifeLab/Sarek/pull/689 for details

  email = 'name@mail.nl'
}

//UMCU HPC Singularity settings
singularity {
  enabled = true
  autoMounts = true
  runOptions = '-B /hpc -B $TMPDIR:$TMPDIR'
  cacheDir = '/hpc/local/CentOS7/cog_bioinf/singularity_cache'
}

//resources customized for processes
process {
  executor = 'slurm'

  //customized resource settings, fine tune as required
   withName : 'get_software_versions' {
      time = '1h'
      memory = '2G'
   }
   
   withName : 'FastQCFQ' {
      time = '8h'
      memory = '8G'
   }
   
   withName : 'MarkDuplicates' {
      time = '48h'
   }
   
   withName : 'VEP' {
      time = '48h'
      memory = '16G'
   }  
   withName : 'VEP' {
      time = '48h'
      memory = '16G'
   }  
}

//Tells nextflow to cleanup work directory after succesful run
cleanup = true
```

#### Modify nextflow.config

The next step is to modify the nextflow.config in order for sarek to be able to properly find and use the custom config file. The nextflow.config file can be found in the sarek folder and in order for custom config files to properly work a line must be added for each specific custom config file in the section: 

```
profiles {
...
  test                { includeConfig 'conf/test.config' }
  test_annotation     { includeConfig 'conf/test_annotation.config' }
  test_use_gatk_spark { includeConfig 'conf/test_use_gatk_spark.config' }
...
}
```

Add the following line to that section in order to tell sarek where to find the config we just created:

```
umcu_grch37         { includeConfig 'conf_custom/umcu_grch37.config' }
```
This tells sarek that the config can be found in the 'conf_custom' subfolder and has the filename 'umcu_grch37.config'

#### (i)genomes.config

The igenomes.config and genomes.config files can be found in the sarek//conf subfolder and contains all the locations of the various resources used. An overview of options and which tools use them

 * ac_loci & ac_loci_gc<br>ascat<br>
 * bwa<br>bwa<br>
 * chr_dir & chr_len<br>control-freec<br>
 * dbsnp & dbsnp_index<br>BQSR, haplotypecaller, controlfreec<br>
 * germline_resource & germline_resource<br>mutect2<br>
 * intervals<br>paralellisation<br>
 * known_indels & known_indels_index<br>BQSR<br>
 * mappability<br>control-freec<br>
 * snpeff_db<br>snpEff annotate<br>
 * species<br>vep<br>
 * vep_cache_version<br>vep

In order to add new genome resource, an entry to either the genomes.config (by default) or the igenomes.config must added. For example, this adds a GRCm38 entry to the genomes.config file:

```
'GRCm38' {
        bwa                     = "${params.genomes_base}/bwa_index/v0.7.17/Mm_GRCm38_gatk_sorted.fasta.{amb,ann,bwt,pac,sa}"
        chr_dir                 = "${params.genomes_base}/chr_files"
        chr_length              = "${params.genomes_base}/Mm_GRCm38_gatk_sorted.len"
        dbsnp                   = "/hpc/ubec/resources/tools/rnaseq-nf/genome_files/GRCm38/MouseGenomeProject/mgp.v5.merged.snps_all.dbSNP142.vcf.gz"
        dbsnp_index             = "/hpc/ubec/resources/tools/rnaseq-nf/genome_files/GRCm38/MouseGenomeProject/mgp.v5.merged.snps_all.dbSNP142.vcf.gz.tbi"
        dict                    = "${params.genomes_base}/Mm_GRCm38_gatk_sorted.dict"
        fasta                   = "${params.genomes_base}/Mm_GRCm38_gatk_sorted.fasta"
        fasta_fai               = "${params.genomes_base}/Mm_GRCm38_gatk_sorted.fasta.fai"
        intervals                 = "${params.genomes_base}/Mm_GRCm38_gatk_sorted.interval_list"
        known_indels            = "/hpc/ubec/resources/tools/rnaseq-nf/genome_files/GRCm38/MouseGenomeProject/mgp.v5.merged.indels.dbSNP142.normed.vcf.gz"
        known_indels_index      = "/hpc/ubec/resources/tools/rnaseq-nf/genome_files/GRCm38/MouseGenomeProject/mgp.v5.merged.indels.dbSNP142.normed.vcf.gz.tbi"
        mappability             = "/hpc/ubec/resources/tools/rnaseq-nf/genome_files/GRCm38/Annotation/Control-FREEC/GRCm38_68_mm10.gem"
        snpeff_db               = 'GRCm38.99'
        species                 = 'mouse'
        vep_cache_version       = '99'
    }
```

### Notes

Sometimes Control-FREEC can give issues due to an incompatible chr_len file, resulting in empty output. The fix is to adjust chr_length file, \<genome\>.len, to incl 'chr' in chr names for the 2nd column and no 'chr' in the first column , needed for controlfreec to work. Otherwise all reads are ignored.

For example, when the fasta has no chr prefix, generate the .len as follows:
```
#head -24 used to only include all chr up to and incl Y, adjust as desired
awk '{print $1"\tchr"$1"\t"$2'} <genome>.fa.fai | head -24> <genome>.len
```

When the fasta DOES have a chr prefix, generate the .len as follows:
```
#head -24 used to only include all chr up to and incl Y, adjust as desired
awk '{gsub("chr", "", $1); print $1"\tchr"$1"\t"$2'} <genome>.fa.fai | head -24> <genome>.len
```


### Manually download singularity images
While sarek can download required images automatically this can sometimes cause issues (for example due to space or permission limitations), if this is the case the images can be pulled manually as follows

GRCh37
```
singularity pull --name nfcore-sarekvep-2.7.GRCh37.img docker://nfcore/sarekvep:2.7.GRCh37
singularity pull --name nfcore-sareksnpeff-2.7.GRCh37.img docker://nfcore/sareksnpeff:2.7.GRCh37
```

#### NOTE
When pulling singularity images results in 'out of space' errors one needs to properly set SINGLUARITY_CACHEDIR (and SINGULARITY_TMPDIR,SINGULARITY_LOCALCACHEDIR ?). See  https://ubccr.freshdesk.com/support/solutions/articles/13000065620-singularity-build-error-no-space-left-on-device for details.

## Configure Nextflow
To do...

## Configure processes
To do...

## Modify code

Some modifications have been made to the sarek code in order to optimize usage or make it usable with the custom genome configs. The following changes are made to the main.nf file in the sarek folder:

### Disable mpileup and use bam files for control-freec
Line 125 and 135. Change occurences of:
```
case 'controlfreec': tsvPath = "${params.outdir}/VariantCalling/TSV/control-freec_mpileup.tsv"; break
```
to:
```
case 'controlfreec': tsvPath = "${params.outdir}/Preprocessing/TSV/recalibrated.tsv"; break
```

Line 149. Change:<br>
```case 'controlfreec': inputSample = extractPileup(tsvFile); break```
<br>to:<br>
```case 'controlfreec': inputSample = extractBam(tsvFile); break```

In the section 
```
================================================================================
                            GERMLINE VARIANT CALLING
================================================================================
```
Line 1831. Change:
```
(bamMantaSingle, bamStrelkaSingle, bamTIDDIT, bamFreebayesSingleNoIntervals, bamHaplotypeCallerNoIntervals, bamRecalAll) = bam_recalibrated.into(6)
```
to:
```
(bamMantaSingle, bamStrelkaSingle, bamTIDDIT, bamFreebayesSingleNoIntervals, bamHaplotypeCallerNoIntervals, bamControlFREECSingle, bamRecalAll) = bam_recalibrated.into(7)
```

In the section 
```
================================================================================
                             SOMATIC VARIANT CALLING
================================================================================
```
Line 2212. Change
```
(pairBamManta, pairBamStrelka, pairBamStrelkaBP, pairBamMsisensor, pairBamCNVkit, pairBam) = pairBam.into(6)
```
to:
```
(pairBamManta, pairBamStrelka, pairBamStrelkaBP, pairBamMsisensor, pairBamCNVkit, pairBamControlFREEC, pairBam) = pairBam.into(7)
```

Line 3083-3189: Remove the entire section (starting from //STEP MPILEUP.1 up to but not including // STEP CONTROLFREEC.1 - CONTROLFREEC):
```
// STEP MPILEUP.1

process Mpileup {
    label 'cpus_1'
    label 'memory_singleCPU_2_task'
    
    ...
    
    mpileupOut = mpileupOut.map {
    idPatientNormal, idSampleNormal, mpileupOutNormal,
    idSampleTumor, mpileupOutTumor ->
    [idPatientNormal, idSampleNormal, idSampleTumor, mpileupOutNormal, mpileupOutTumor]
}    
```
replace with:
```
bamControlFreeC = Channel.empty()
if (step == 'controlfreec') bamControlFreeC = inputSample
```

Replace the entire processes ControlFREEC {} and ControlFREECSingle {}

Replace 'process ControlFREEC {}' with:
```
process ControlFREEC {
    label 'cpus_8'

    tag "${idSampleTumor}_vs_${idSampleNormal}"

    publishDir "${params.outdir}/VariantCalling/${idSampleTumor}_vs_${idSampleNormal}/Control-FREEC", mode: params.publish_dir_mode

    input:
        set idPatient, idSampleNormal, file(bamNormal), file(baiNormal), idSampleTumor, file(bamTumor), file(baiTumor) from pairBamControlFREEC
        file(chrDir) from ch_chr_dir
        file(mappability) from ch_mappability
        file(chrLength) from ch_chr_length
        file(dbsnp) from ch_dbsnp
        file(dbsnpIndex) from ch_dbsnp_tbi
        file(fasta) from ch_fasta
        file(fastaFai) from ch_fai
        file(targetBED) from ch_target_bed

    output:
        set idPatient, idSampleNormal, idSampleTumor, file("${idSampleTumor}.bam_CNVs"), file("${idSampleTumor}.bam_ratio.txt") into controlFreecViz
        set file("*.bam*"), file("${idSampleTumor}_vs_${idSampleNormal}.config.txt") into controlFreecOut

    when: 'controlfreec' in tools

    script:
    config = "${idSampleTumor}_vs_${idSampleNormal}.config.txt"
    gender = genderMap[idPatient]
    // Window has higher priority than coefficientOfVariation if both given
    window = params.cf_window ? "window = ${params.cf_window}" : ""
    coeffvar = params.cf_coeff ? "coefficientOfVariation = ${params.cf_coeff}" : ""
    use_bed = params.target_bed ? "captureRegions = ${targetBED}" : ""
    // This parameter makes Control-FREEC unstable (still in Beta according to the developers)
    // so we disable it by setting it to its default value (it is disabled by default)
    //min_subclone = params.target_bed ? "30" : "20"
    min_subclone = 100
    readCountThreshold = params.target_bed ? "50" : "10"
    breakPointThreshold = params.target_bed ? "1.2" : "0.8"
    breakPointType = params.target_bed ? "4" : "2"
    mappabilitystr = params.mappability ? "gemMappabilityFile = \${PWD}/${mappability}" : ""
    contamination_adjustment = params.cf_contamination_adjustment ? "contaminationAdjustment = TRUE" : ""
    contamination_value = params.cf_contamination ? "contamination = ${params.cf_contamination}" : ""
    """
    touch ${config}
    echo "[general]" >> ${config}
    echo "BedGraphOutput = TRUE" >> ${config}
    echo "chrFiles = \${PWD}/${chrDir.fileName}" >> ${config}
    echo "chrLenFile = \${PWD}/${chrLength.fileName}" >> ${config}
    echo "forceGCcontentNormalization = 1" >> ${config}   #no_iap
    echo "maxThreads = ${task.cpus}" >> ${config}
    echo "minimalSubclonePresence = ${min_subclone}" >> ${config}
    echo "ploidy = ${params.cf_ploidy}" >> ${config}
    echo "sex = ${gender}" >> ${config}	#no_iap
    echo "readCountThreshold = ${readCountThreshold}" >> ${config}	#no_iap
    echo "breakPointThreshold = ${breakPointThreshold}" >> ${config}	#no_iap
    echo "breakPointType = ${breakPointType}" >> ${config}	#no_iap
    echo "${window}" >> ${config}
    echo "${coeffvar}" >> ${config}	#no_iap
    echo "${mappabilitystr}" >> ${config}
    echo "${contamination_adjustment}" >> ${config}
    echo "${contamination_value}" >> ${config}
    echo "" >> ${config}    
    echo "[control]" >> ${config}
    echo "inputFormat = BAM" >> ${config}
    echo "mateFile = \${PWD}/${bamNormal}" >> ${config}
    # echo "mateOrientation = FR" >> ${config}
    echo "" >> ${config}
    echo "[sample]" >> ${config}
    echo "inputFormat = BAM" >> ${config}
    echo "mateFile = \${PWD}/${bamTumor}" >> ${config}
    # echo "mateOrientation = FR" >> ${config}
    echo "" >> ${config}
    echo "[target]" >> ${config}
    echo "${use_bed}" >> ${config}
    freec -conf ${config}

    #output is created usig bam names, rename to sample name
    for f in ${bamNormal}_*; do mv \${f} \${f/${bamNormal}/${idSampleNormal}.bam}; done
    for f in ${bamTumor}_*; do mv \${f} \${f/${bamTumor}/${idSampleTumor}.bam}; done
    """
}
```

Replace process ControlFREECSingle {} with:
```
process ControlFREECSingle {
    label 'cpus_8'

    tag "${idSample}"

    publishDir "${params.outdir}/VariantCalling/${idSample}/Control-FREEC", mode: params.publish_dir_mode

    input:
        set idPatient, idSample, file(bam), file(bai) from bamControlFREECSingle
        file(chrDir) from ch_chr_dir
        file(mappability) from ch_mappability
        file(chrLength) from ch_chr_length
        file(dbsnp) from ch_dbsnp
        file(dbsnpIndex) from ch_dbsnp_tbi
        file(fasta) from ch_fasta
        file(fastaFai) from ch_fai
        file(targetBED) from ch_target_bed

    output:
        set idPatient, idSample, file("${idSample}.bam_CNVs"), file("${idSample}.bam_ratio.txt") into controlFreecVizSingle
        set file("*.bam*"), file("${idSample}.config.txt") into controlFreecOutSingle

    when: 'controlfreec' in tools

    script:
    config = "${idSample}.config.txt"
    gender = genderMap[idPatient]
    // Window has higher priority than coefficientOfVariation if both given
    window = params.cf_window ? "window = ${params.cf_window}" : ""
    coeffvar = params.cf_coeff ? "coefficientOfVariation = ${params.cf_coeff}" : ""
    use_bed = params.target_bed ? "captureRegions = ${targetBED}" : ""
    // This parameter makes Control-FREEC unstable (still in Beta according to the developers)
    // so we disable it by setting it to its default value (it is disabled by default)
    //min_subclone = params.target_bed ? "30" : "20"
    min_subclone = 100
    readCountThreshold = params.target_bed ? "50" : "10"
    breakPointThreshold = params.target_bed ? "1.2" : "0.8"
    breakPointType = params.target_bed ? "4" : "2"
    mappabilitystr = params.mappability ? "gemMappabilityFile = \${PWD}/${mappability}" : ""
    contamination_adjustment = params.cf_contamination_adjustment ? "contaminationAdjustment = TRUE" : ""
    contamination_value = params.cf_contamination ? "contamination = ${params.cf_contamination}" : ""
    """
    touch ${config}
    echo "[general]" >> ${config}
    echo "BedGraphOutput = TRUE" >> ${config}
    echo "chrFiles = \${PWD}/${chrDir.fileName}" >> ${config}
    echo "chrLenFile = \${PWD}/${chrLength.fileName}" >> ${config}
    echo "forceGCcontentNormalization = 1" >> ${config}
    echo "maxThreads = ${task.cpus}" >> ${config}
    echo "minimalSubclonePresence = ${min_subclone}" >> ${config}
    echo "ploidy = ${params.cf_ploidy}" >> ${config}
    echo "sex = ${gender}" >> ${config}
    echo "readCountThreshold = ${readCountThreshold}" >> ${config}
    echo "breakPointThreshold = ${breakPointThreshold}" >> ${config}
    echo "breakPointType = ${breakPointType}" >> ${config}
    echo "${window}" >> ${config}
    echo "${coeffvar}" >> ${config}
    echo "${mappabilitystr}" >> ${config}
    echo "${contamination_adjustment}" >> ${config}
    echo "${contamination_value}" >> ${config}
    echo "" >> ${config}
    echo "[sample]" >> ${config}
    echo "inputFormat = BAM" >> ${config}
    echo "mateFile = \${PWD}/${bam}" >> ${config}
    # echo "mateOrientation = FR" >> ${config}
    echo "" >> ${config}
    echo "[target]" >> ${config}
    echo "${use_bed}" >> ${config}
    freec -conf ${config}
    #output is created usig bam names, rename to sample name
    for f in ${bam}_*; do mv \${f} \${f/${bam}/${idSample}.bam}; done
    """
}
```

In the processes ControlFreecViz and ControlFreecVizSingle, remove the references to the bafTumor file

process ControlFreecViz:
```
set idPatient, idSampleNormal, idSampleTumor, file(cnvTumor), file(ratioTumor), file(bafTumor) from controlFreecViz
...
cat /opt/conda/envs/nf-core-sarek-${workflow.manifest.version}/bin/makeGraph.R | R --slave --args 2 ${ratioTumor} ${bafTumor}
```
to:
```
set idPatient, idSampleNormal, idSampleTumor, file(cnvTumor), file(ratioTumor) from controlFreecViz
...
cat /opt/conda/envs/nf-core-sarek-${workflow.manifest.version}/bin/makeGraph.R | R --slave --args 1 ${ratioTumor}
```

likewise for process ControlFreecVizSingle:
```
set idPatient, idSampleTumor, file(cnvTumor), file(ratioTumor), file(bafTumor) from controlFreecVizSingle
...
cat /opt/conda/envs/nf-core-sarek-${workflow.manifest.version}/bin/makeGraph.R | R --slave --args 2 ${ratioTumor} ${bafTumor}
```
to:
```
set idPatient, idSampleTumor, file(cnvTumor), file(ratioTumor) from controlFreecVizSingle
...
cat /opt/conda/envs/nf-core-sarek-${workflow.manifest.version}/bin/makeGraph.R | R --slave --args 1 ${ratioTumor}
```
### Modifications for using VEP with custom genome names

In the section 
```
================================================================================
                               CHECKING REFERENCES
================================================================================
```
Add the following line:
```
params.vep_genome = params.genome && ('vep' in tools || 'merge' in tools) ? params.genomes[params.genome].vep_genome ?: null : null
```

In the processes VEP {} and VEPmerge {}, replace the following line:
```
    genome = params.genome == 'smallGRCh37' ? 'GRCh37' : params.genome
```
with:
```
    genome = (params.vep_genome ) ? params.vep_genome : params.genome
```
#### The following change must be made to nextflow.config in the main nextflow folder!
Add the following line underneat the // Annotation section (for example under '  vep_cache = null // No directory for VEP cache') :
```
  vep_genome = null // No custom genome name for VEP
```
#### The following change must be made to nextflow_schema.json in the main nextflow folder! (Don't forget the comma seperator at the start)
Add the following code in the "annotation" section (it can be added under the "vep_catche" entry:
```
    ,                
    "vep_genome": {
        "type": "string",
        "default": "null",
        "fa_icon": "fas fa-wrench",
        "description": "Set name for VEP genome image base",
        "hidden": true
    }
```

In the config used with the custom genome, the following entry must be created to be able to pull the correct VEP and SnpEff images:

```
process {
   withName:Snpeff {
     container = 'nfcore/sareksnpeff:2.7.1.GRCh38'
     maxForks = 1
   }
   withLabel:VEP {
     container = 'nfcore/sarekvep:2.7.1.GRCh38'
     maxForks = 1
   }
}
```

If the process section already exists, just add the content to it.

### Modification Mutect2 germline resource check and usage
Underneath the following line:

```
if ('mutect2' in tools && !(params.pon)) log.warn "[nf-core/sarek] Mutect2 was requested, but as no panel of normals were given, results will not be optimal"
```

Add this line:
```
if ('mutect2' in tools && !(params.germline_resource)) log.warn "[nf-core/sarek] Mutect2 was requested, but as no germline resource was given, results will not be optimal"
```

In the process Mutect2 {} and Mutect2Single {}, below the line:
```
    PON = params.pon ? "--panel-of-normals ${pon}" : ""
```

add the following line:
```
    GLR = params.germline_resource ? "--germline-resource ${germlineResource}" : ""
```

and replace the line:
```
      --germline-resource ${germlineResource} \
```
with:
```
      ${GLR} \
```
### Add custom VCF annotation

In the file 'nextflow.config', under the //Annotation section, add the following lines:

```
  custom_vcf = false // No Custom VCF file
  custom_vcf_tbi = false // No Custom VCF index file 
  custom_vcf_fields = null // No Custom VCF fields
```
In the file 'nextflow_schema.json', in the section '"annotation": {...}' add the following lines:

```
                "custom_vcf": {
                    "type": "string",
                    "default": "null",
                    "fa_icon": "fas fa-file",
                    "description": "Path to custom vcf annotation file",
                    "hidden": true
                },                
                "custom_vcf_tbi": {
                    "type": "string",
                    "default": "null",
                    "fa_icon": "fas fa-file",
                    "description": "Path to custom vcf annotation index file",
                    "hidden": true
                },  
                "custom_vcf_fields": {
                    "type": "string",
                    "default": "null",
                    "fa_icon": "fas fa-wrench",
                    "description": "Fields to include from custom VCF",
                    "hidden": true
                }
```

In the file 'main.nf' add the following lines...

Under '// Check parameters':

```
if ('customvcf' in tools && (!params.custom_vcf_fields || !params.custom_vcf)) exit 1, 'Please specify both --custom_vcf and --custom_vcf_fields, when using "customvcf" annotation tool'
if ('customvcf' in tools && (!hasExtension(params.custom_vcf, "vcf.gz") || hasExtension(params.input, "vcf"))) exit 1, 'CustomVCF requires bzipped input and annotation files'
```

Under '// Initialize channels with files based on params':

```
ch_custom_vcf = params.custom_vcf ? Channel.value(file(params.custom_vcf)) : "null"
ch_custom_vcf_tbi = params.custom_vcf_tbi ? Channel.value(file(params.custom_vcf_tbi)) : "null"
```

Under '// Header log info' in the 'PRINT PARAMETER SUMMARY'

```
if ('customvcf' in tools) {
    summary['CustomVCF'] = "Options"
    if (params.custom_vcf) summary['CustomVCF'] = params.custom_vcf
    if (params.custom_vcf_tbi) summary['CustomVCF'] = params.custom_vcf_tbi
    if (params.custom_vcf_fields) summary['CustomVCFFields'] = params.custom_vcf_fields
}
```

Change the line:
```
(vcfSnpeff, vcfVep) = vcfAnnotation.into(2)
```
to
```
(vcfSnpeff, vcfVep, vcfCustom) = vcfAnnotation.into(3)
```

Above the section 'MultiQC' and below the process CompressVCFvep (and more specifically the line '
compressVCFOutVEP = compressVCFOutVEP.dump(tag:'VCF')' ), add the following block:

```
//STEP 3. CUSTOM VCF ANNOTATION
process VCFCustom {
    tag "${idSample} - ${variantCaller} - ${vcf}"

    publishDir params.outdir, mode: params.publish_dir_mode, saveAs: {
        if (it == "${reducedVCF}_customVCF.ann.vcf") null
        else "Reports/${idSample}/customVCF/${it}"
    }

    input:
        set variantCaller, idSample, file(vcf) from vcfCustom
        file(custom_vcf) from ch_custom_vcf

    output:
        set variantCaller, idSample, file("${reducedVCF}_customVCF.ann.vcf") into customVCF

    when: 'customvcf' in tools

    script:
    reducedVCF = reduceVCF(vcf.fileName)
    vcffields = params.custom_vcf_fields

    """
    mkdir ${reducedVCF}
    bcftools annotate \
        -o ${reducedVCF}_customVCF.ann.vcf.gz \
        -a ${custom_vcf} \
        -O z \
        -c ${vcffields} \
        ${vcf}
    tabix ${reducedVCF}_customVCF.ann.vcf.gz
        
    rm -rf ${reducedVCF}
    """
}


process VCFCustomMerge {
    tag "${idSample} - ${variantCaller} - ${vcf}"

    publishDir params.outdir, mode: params.publish_dir_mode, saveAs: {
        if (it == "${reducedVCF}_customVCF.ann.vcf") null
        else "Reports/${idSample}/customVCF/${it}"
    }

    input:
        set variantCaller, idSample, file(vcf), file(idx)  from compressVCFOutVEP
        file(custom_vcf) from ch_custom_vcf

    output:
        set variantCaller, idSample, file("${reducedVCF}_customVCF.ann.vcf") into customVCFmerge

    when: 'customvcf' in tools && 'merge' in tools

    script:
    reducedVCF = reduceVCF(vcf.fileName)
    vcffields = params.custom_vcf_fields

    """
    mkdir ${reducedVCF}
    bcftools annotate \
        -o ${reducedVCF}_customVCF.ann.vcf.gz \
        -a ${custom_vcf} \
        -O z \
        -c ${vcffields} \
        ${vcf}
    tabix ${reducedVCF}_customVCF.ann.vcf.gz
        
    rm -rf ${reducedVCF}
    """
}

compressVCFOutCustom = customVCF.mix(customVCFmerge)

compressVCFOutCustom = compressVCFOutCustom.dump(tag:'VCF')
```

## Running the pipeline

Extended information on using sarek can be found at: https://nf-co.re/sarek/usage

The Sarek pipeline can be started from a number of steps, defined by the --step parameter. Some of these steps require additional tools to be set. Most of these steps require a tsv file as input, only the mapping step also accepts a folder containing a single germline sample fastq folder. When running the Sarek pipeline it will also automatically generate these TSV files for all and each individual sample. The exact format of the TSV file depends on the starting step.

Sarek can be started from any of these steps:

### Mapping
```
--input <fastqs.tsv> --step mapping
```
The mapping TSV file should contain the columns:
```
subject sex status sample lane fastq1 fastq2
```
Example:
```
SUBJECT_ID	XX	0	SAMPLE_ID	1	/samples/normal1_1.fastq.gz
SUBJECT_ID	XX	0	SAMPLE_ID	2	/samples/normal2_1.fastq.gz
SUBJECT_ID	XX	0	SAMPLE_ID	3	/samples/normal3_1.fastq.gz
```

### Recalibrate
```
--input <bams.tsv> --step recalibrate
```
The recalibrate TSV file should contain the following columns:
```
subject sex status sample bam bai recaltable
```
### variant_calling
```
--input <bams.tsv> --step variant_calling
```
The variant_calling TSV file should contain the following columns:
```
subject sex status sample bam bai
```
### ControlFREEC
```
--input <bams.tsv> --step ControlREEC
```
The Control-FREEC TSV file should contain the following columns:
```
subject sex status sample bam bai
```

Note! The original sarek pipeline uses mpileup files for control-FREEC, this has been modified to accept .bam files as the mpileup files are extremely large and this will lead to issues when processing many (WGS) samples.

### Annotate
```
--input <input.vcfs> --step annotate
```
Annotate accepts a sorted vcf file as input, multiple files can be specified using global paths and by enclosing the input in quotes.

Example:
```
--step annotate --input "results/VariantCalling/*/{HaplotypeCaller,Manta,Mutect2,Strelka,TIDDIT}/*.vcf.gz"
```



### Executing the pipeline

The following command can be used to actually run the sarek pipeline:

GRCh37 exome:
```
/hpc/ubec/tools/nextflow_20.10.0/nextflow run /hpc/ubec/projects/sarek/sarek/main.nf \
-profile umcu_grch37 \
--project exome_test \
--input /hpc/ubec/projects/sarek/exome_test/TSV/NA18505.tsv \
--step mapping \
--outdir /hpc/ubec/projects/sarek/exome_test/output \
-w /hpc/ubec/projects/sarek/exome_test/output/work \
-resume
```

GRCm38 Mouse:
This starts at the mapping step, using the umcu_grcm38 custom profile. The tools specified in --tools are executed.
```
/hpc/ubec/tools/nextflow_20.10.0/nextflow run /hpc/ubec/projects/sarek/sarek/main.nf \
-profile umcu_grcm38 \
--input /hpc/ubec/projects/sarek/test_runs/mouse_arne/input/normal_tumor.tsv \
--step mapping \
--tools cnvkit,freebayes,haplotypecaller,manta,mpileup,mutect2,snpeff,strelka,tiddit,msisensor,vep,merge \
--outdir /hpc/ubec/projects/sarek/test_runs/mouse_arne/output \
-w /hpc/ubec/projects/sarek/test_runs/mouse_arne/output/work \
-resume
```

## Available tools
* ASCAT<br>
https://github.com/VanLoo-lab/ascat<br><br>
Infer tumor purity, ploidy and allele specific copy number profiles

* CNVkit*<br>
https://github.com/etal/cnvkit<br><br>
Detecting copy number variants and alterations genome wide from high throughput sequencing

* ControlFREEC*<br>
https://github.com/BoevaLab/FREEC<br><br>
Copy number and genotype annotation for whole genome and whole exome sequencing data. Detecting copy number changes and imbalances

* FreeBayes<br>
https://github.com/freebayes/freebayes<br><br>
A haplotype-based variant detector for small polymorphisms (snps, indels mnp and complex events smaller then the length of a short-read sequencing alignment

* HaplotypeCaller<br>
https://gatk.broadinstitute.org/hc/en-us/articles/360037225632-HaplotypeCaller<br><br>
Call germline SNPs and indels via local re-assembly of haplotypes

* Manta<br>
https://github.com/Illumina/manta<br><br>
Manta calls structural variants (SVs) and indels from mapped paired-end sequencing reads and is optimized for analysis of germline variation in small sets of individuals and somatic variation in tumor/normal sample pairs.

* Mpileup<br>
http://www.htslib.org/doc/samtools-mpileup.html<br><br>
produces "pileup" textual format from an alignment

* MSIsensor<br>
https://github.com/ding-lab/msisensor<br><br>
Microsatellite instability detection user tumor only or paired tumor-normal data

*	Mutect2<br>
https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2<br><br>
Call somatic SNVs and indels via local assembly of haplotypes

*	Strelka2<br>
https://github.com/Illumina/strelka<br><br>
Small variant caller optimized for analysis of germline variation in small cohorts and somatic variation in tumor/normal pair samples

*	TIDDIT<br>
https://github.com/SciLifeLab/TIDDIT<br><br>
A tool used to identify chromosomal rearrangements using mate pair or paired end sequencing data. TIDDIT identifies intra and inter-chromosomal translocations, deletions, tandem-duplications and inversions, using supplementary alignments as well as discordant pairs.

*	snpEff<br>
http://pcingola.github.io/SnpEff<br><br>
Genetic variant annotation and functional effect prediction toolbox. It annotates and predicts the effects of genetic variants on genes and proteins (such as amino acid changes).

*	VEP<br>
https://github.com/Ensembl/ensembl-vep<br><br>
(Variant Effect Predictor) predicts the functional effects of genomic variants.

*	Merge ???<br>

## Workflow

![GitHub Logo](/Sarek_pipeline_tools_workflow.jpg)

## Test Run
  
Execute the following in order to setup and do a testrun with the pipeline

```
cp -av /hpc/cog_bioinf/ubec/useq/processed_data/external/REN5302/input/REN5302_1/09-06576/*.fastq.gz /hpc/cog_bioinf/ubec/users/flip/pipelines/sarek_test/input/single_sample_fastq/
```
