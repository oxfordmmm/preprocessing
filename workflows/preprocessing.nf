// enable dsl2
nextflow.enable.dsl = 2

// import modules
include {preprocessing_checkFqValidity} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_countReads} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_fastp} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_fastQC} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_kraken2} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_mykrobe} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_bowtie2} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_identifyBacterialContaminants} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_downloadContamGenomes} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_mapToContamFa} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_reKraken} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_reMykrobe} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_summarise} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_checkBamValidity} from '../modules/preprocessingModules.nf' params(params)
include {preprocessing_bam2fastq} from '../modules/preprocessingModules.nf' params(params)

// define workflow component
workflow preprocessing {

    take:
      input_files
      krakenDB
      bowtie_dir

    main:

      if ( params.filetype == "bam" ) {
          
          preprocessing_checkBamValidity(input_files)

          preprocessing_bam2fastq(preprocessing_checkBamValidity.out.checkValidity_bam)

          preprocessing_countReads(preprocessing_bam2fastq.out.bam2fastq_fqs)
      }

      if ( params.filetype == "fastq" ) {

          preprocessing_checkFqValidity(input_files)

          preprocessing_countReads(preprocessing_checkFqValidity.out.checkValidity_fqs)
      }

      preprocessing_fastp(preprocessing_countReads.out.countReads_fqs)

      preprocessing_fastQC(preprocessing_fastp.out.fastp_fqs)

      preprocessing_kraken2(preprocessing_fastp.out.fastp_fqs, krakenDB.toList())

      preprocessing_mykrobe(preprocessing_kraken2.out.kraken2_fqs)

      preprocessing_bowtie2(preprocessing_kraken2.out.kraken2_fqs, bowtie_dir)

      preprocessing_identifyBacterialContaminants(preprocessing_mykrobe.out.mykrobe_report, preprocessing_kraken2.out.kraken2_report)

      preprocessing_downloadContamGenomes(preprocessing_identifyBacterialContaminants.out.contam_list)

      preprocessing_mapToContamFa(preprocessing_bowtie2.out.bowtie2_fqs, preprocessing_downloadContamGenomes.out.contam_fa)

      preprocessing_reKraken(preprocessing_mapToContamFa.out.reClassification_fqs, krakenDB.toList())

      preprocessing_reMykrobe(preprocessing_mapToContamFa.out.reClassification_fqs)

      preprocessing_summarise(preprocessing_reMykrobe.out.reMykrobe_report, preprocessing_reKraken.out.reKraken_report)      
}
