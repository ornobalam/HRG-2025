#!/usr/bin/env nextflow

// ######################################
// #    Rafal Gutaker, NYU, 2017        #
// #    Pipeline that performs:         #
// #    - mapping to reference          #
// #    - sorting reads		        #
// #    - removal of PCR duplicates     #
// #    - calling haplotypes            #
// #					#
// #					#
// #    Updated to GATK4 best practices #
// #	by Ornob Alam, NYU, 2020	#
// #                                    #
// ######################################


params.help=""
params.exe="local"

if (params.help) {
        log.info " "
        log.info "This is Nextflow pipeline for processing rice 3k dataset. Most parameters are stored in file process_3k.conf"
        log.info " "
        log.info "Usage: nextflow run process_3k.nf -c process_3k.conf --ref --list --chrom --(other options)"
        log.info "Options:"
        log.info "--help\t[BOOLEAN]\tShow this help message"
        log.info "--ref\t[STRING]\tPath to the indexed referece fasta file [OBLIGATORY]"
        log.info "--list\t[STRING]\tPath to the file with run IDs and fastq files to be processed [OBLIGATORY]"
        log.info "--exe\t[STRING]\tExecutor mode, -local- or -slurm- [DEFUALT: local]"
        log.info " "
        exit 1
}

// Initalize Input
DAT = file("${params.list}")
REF = file("${params.ref}")




// Create Input Channel
SampleData = Channel.fromPath("${DAT}").splitCsv(header: ['SID','RID','P1','P2'], skip: 0, by:1, sep:",")

// ########### Run BWA #############
process bwa {
	errorStrategy 'finish'	

        executor = "${params.exe}"
	if ("${params.exe}" == "slurm")
	{
        	clusterOptions = "--cpus-per-task=${params.bwa_cpu} --time=${params.bwa_rt} --mem=${params.bwa_vmem}"
	}

        input:
         val(RAW) from SampleData

        output:
         set val(ID), val(SID), file({ "${MAP}" }) into aligned

        script:

	 SID = "${RAW.SID}"
	 ID = "${RAW.RID}"
         RG = "\'@RG\\tID:${RAW.P1}\\tSM:${RAW.SID}\\tPL:ILLUMINA\'"
         MAP = "${RAW.RID}.sam"

         P1 = file("${RAW.P1}")
         P2 = file("${RAW.P2}")

         """
     module purge
	 module load bwa/intel/0.7.17
         ${params.bwa_bin} mem ${params.bwa_param} -M -R ${RG} ${REF} ${P1} ${P2} > ${MAP}
	 """
}


// ########### Sort SAM ###############

process sort {

	errorStrategy 'finish'

        executor = "${params.exe}"
        if ("${params.exe}" == "slurm")
        {
        	clusterOptions = "--cpus-per-task=${params.srt_cpu} --time=${params.srt_rt} --mem=${params.srt_vmem}"
	}

        input:
         set val(ID), val(SID), file(SAM) from aligned

        output:
         set val(ID), val(SID), file({ "${SBAM}" }) into sorted

        script:

	SBAM = "${ID}.sorted.bam"
	del_sam = SAM.getName()

	"""
    module purge
    module load picard/2.27.5
	${params.srt_bin} INPUT=${SAM} OUTPUT=${SBAM} SORT_ORDER=coordinate
	"""
	}

// ####### MERGE FILE CHANNELS #########


sorted
	.map {id, sid, file -> tuple(sid, file) }
	.groupTuple()
	.set { merg_sid }


// ###### Remove Read Duplicates #######
process rmdup {

	errorStrategy 'finish'

        executor = "${params.exe}"
        if ("${params.exe}" == "slurm")
        {
		clusterOptions = "--cpus-per-task=${params.ddp_cpu} --time=${params.ddp_rt} --mem=${params.ddp_vmem}"
	}

        input:
         set val(SID), file(SBAM) from merg_sid

        output:
         set val(SID), file({ "${RMDUP}" }) into rmdup

        script:
	 ALL_IN = SBAM.collect { "INPUT=$it" }.join(' ')
         RMDUP = "${SID}.dedup.bam"
         RMET = "${SID}.dedup.met"
//         del_sbam = SBAM.getName()

         """
        module purge
        module load picard/2.27.5
        ${params.ddp_bin} ${ALL_IN} OUTPUT=${RMDUP} METRICS_FILE=${RMET}
         """
}


// ########### Check BAM ##########

process checkbam {

	errorStrategy 'ignore'

	executor = "${params.exe}"
	if ("${params.exe}" == "slurm")
	{
		clusterOptions = "--cpus-per-task=${params.vb_cpu} --time=${params.vb_rt} --mem=${params.vb_vmem}"
	}


	input:
	set val(SID), file(RMDUP) from rmdup

	output:
	set val(SID), file(RMDUP) into bchecked

	script:

	"""
    module purge
    module load picard/2.27.5
	${params.vb_bin} INPUT=${RMDUP} ${params.vb_param}
	"""
}

// ########### Index BAM ##########
process index {

	errorStrategy 'finish'

        executor = "${params.exe}"
        if ("${params.exe}" == "slurm")
        {
	        clusterOptions = "--cpus-per-task=${params.idx_cpu} --time=${params.idx_rt} --mem=${params.idx_vmem}"
	}


        input:
         set val(SID), file(RMDUP) from bchecked

        output:
         set val(SID), file({ "${RMDUP}" }), file({ "${BAI}" }) into index

        script:
         BAI = "${SID}.dedup.bai"

         """
         module purge
         module load picard/2.27.5
         ${params.idx_bin} INPUT=${RMDUP} OUTPUT=${BAI}
         """

}

// ######## HaplotypeCaller ########

process haplocall {

	errorStrategy 'finish'

	executor = "${params.exe}"
	if ("${params.exe}" == "slurm")
	{
		clusterOptions = "--cpus-per-task=${params.hc_cpu} --time=${params.hc_rt} --mem=${params.hc_vmem}"
	}

 	input:
 	set val(SID), file(RMDUP), file(BAI) from index
 
 	output:
 	file({ "${CALL}" }) into (called)
	file({ "${VCI}" }) into (vcfindex)
 
 	script:
 	CALL = "${SID}.g.vcf"
	VCI = "${SID}.g.vcf.idx"

 	"""
    module purge
	module load gatk/4.2.0.0
 	${params.hc_bin} ${params.hc_param} -R ${REF} -I ${RMDUP} -O ${CALL}	
 	"""
 
}

// ########## Check GVCF ###########

process checkvcf {

	errorStrategy 'ignore'

	executor = "${params.exe}"
	if ("${params.exe}" == "slurm")
	{
		clusterOptions = "--cpus-per-task=${params.vv_cpu} --time=${params.vv_rt} --mem=${params.vv_vmem}"
	}

	input:
	file(CALL) from called
	
	output:
	file(CALL) into vchecked

	script:

	"""
    module purge
	module load gatk/4.2.0.0
	${params.vv_bin} ${params.vv_param} -R ${REF} -V ${CALL}
	"""
}



// ######## Split channel ##########

vchecked
	.into { called_bzip }



// ####### Compress GVCFs ########

process compress {

	errorStrategy 'finish'

	executor = "${params.exe}" 	
	if ("${params.exe}" == "slurm")
	{
		clusterOptions = "--cpus-per-task=${params.bg_cpu} --time=${params.bg_rt} --mem=${params.bg_vmem}"
	}

        input:
        file(CALL) from called_bzip

        output:
        file( "${BZIP}" ) into bzipped

        script:

        BZIP = "${CALL}.gz"

        """
        module purge
        module load htslib/intel/1.20
        ${params.bg_bin} ${params.bg_param} ${CALL} > ${BZIP}
	"""


}

// ####### Split channel #########

bzipped
	.into { bzip_sub; bzip_tab}


// Return filtered gVCFs
bzip_sub.subscribe { println "[IND] $it" }


// ######### Tabix GVCFs #########

process tabix {

	errorStrategy 'finish'

	executor = "${params.exe}"
	if ("${params.exe}" == "slurm")
	{
		clusterOptions = "--cpus-per-task=${params.tx_cpu} --time=${params.tx_rt} --mem=${params.tx_vmem}"
	}

        input:
        file(BZIP) from bzip_tab

        output:
        file( "${TAB}" ) into tabixed

        script:
        TAB = "${BZIP}.tbi"

        """
        module purge
        module load htslib/intel/1.20
        ${params.tx_bin} ${params.tx_param} ${BZIP}
        """
}


// Return filtered gVCFs
tabixed.subscribe { println "[IND] $it" }
