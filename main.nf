#!/usr/bin/env nextflow

// enable dsl2
nextflow.enable.dsl=2

// import subworkflows
include {preprocessing} from './workflows/preprocessing.nf'

// main workflow
workflow {

    // confirm that mandatory parameters have been set and that the conditional parameter, --pattern, has been used appropriately
    if ( params.input_dir == "" ) {
        exit 1, "error: --input_dir is mandatory (run with --help to see parameters)"
    }
    if ( params.filetype == "" ) {
	exit 1, "error: --filetype is mandatory (run with --help to see parameters)"
    }
    if ( ( params.filetype == "fastq" ) && ( params.pattern == "" ) ) {
        exit 1, "error: --pattern is mandatory if you are providing fastq input; describes files in --input_dir (e.g. \"*_R{1,2}.fastq.gz\") (run with --help to see parameters)"
    }
    if ( ( params.filetype == "bam" ) && ( params.pattern != "" ) ) {
        exit 1, "error: --pattern should only be set if you are providing fastq input (run with --help to see parameters)"
    }
    if ( params.output_dir == "" ) {
        exit 1, "error: --output_dir is mandatory (run with --help to see parameters)"
    }
    if ( ( params.filetype != "fastq" ) && ( params.filetype != "bam" ) ) {
	exit 1, "error: --filetype is mandatory and must be either \"fastq\" or \"bam\""
    }
    if ( ( params.unmix_myco != "yes" ) && ( params.unmix_myco != "no" ) ) {
	exit 1, "error: --unmix_myco is mandatory and must be either \"yes\" or \"no\""
    }
    if ( ( params.species != "null" ) && ( params.species != "abscessus" ) && ( params.species != "africanum" ) && ( params.species != "avium" ) && ( params.species != "bovis" ) && ( params.species != "chelonae" ) && ( params.species != "chimaera" ) && ( params.species != "fortuitum" ) && ( params.species != "intracellulare" ) && ( params.species != "kansasii" ) && ( params.species != "tuberculosis" ) ) {
	exit 1, "error: --species is optional, but if used should be one of either abscessus, africanum, avium, bovis, chelonae, chimaera, fortuitum, intracellulare, kansasii, tuberculosis"
    }

    // add a trailing slash if it was not originally provided to --input_dir
    inputdir_amended = "${params.input_dir}".replaceFirst(/$/, "/") 

    indir = inputdir_amended
    numfiles = 0

    if ( params.filetype == "bam" ) {
        reads = indir + "*.bam"
        numfiles = file(reads) // count the number of files we are processing; we'll print this when the workflow completes
       
        Channel.fromPath(reads)
               .set{ input_files }
    }
    
    if ( params.filetype == "fastq" ) {
        pattern = params.pattern
	reads = indir + pattern
	numfiles = file(reads) // count the number of files we are processing; we'll print this when the workflow completes

        Channel.fromFilePairs(reads, flat: true, checkIfExists: true, size: -1)
	       .ifEmpty { error "cannot find any reads matching ${pattern} in ${indir}" }
	       .set{ input_files }
    }    

    // call preprocressing subworkflow
    main:
      preprocessing(input_files)
          
}
