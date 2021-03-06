bedGraphToBigWig <- function
### Attempt to create bigWig file.
(bedGraph,
### bedGraph file (input), four tab-separated columns: chrom,
### chromStart, chromEnd, numeric data.
  chromInfo,
### chromInfo file (input), two tab-separated columns: chrom, size in
### bases.
  bigWig
### bigWig file (output).
){
  chrom <- chromStart <- NULL
  ## Above to avoid CRAN NOTE.
  unlink(bigWig)
  bedGraph.dt <- suppressWarnings(fread(
    file=bedGraph,
    col.names=c("chrom", "chromStart", "chromEnd", "value")))
  ## This if statement is needed because bedGraphToBigWig stops with
  ## an error code if there are no data, but we don't want to stop,
  ## even if there are no predicted peaks in some samples.
  if(nrow(bedGraph.dt)){
    sorted.dt <- bedGraph.dt[order(chrom, chromStart)]
    bedGraph.sorted <- paste0(bedGraph, ".sorted")
    fwrite(sorted.dt, bedGraph.sorted, sep="\t", col.names=FALSE, quote=FALSE)
    system.or.stop(paste(
      "bedGraphToBigWig",
      shQuote(bedGraph.sorted),
      shQuote(chromInfo),
      shQuote(bigWig)))
    unlink(bedGraph.sorted)
  }
  file.exists(bigWig)
### TRUE if bigWig was created.
}

bigWigToBedGraph <- function
### Run bigWigToBedGraph command line program.
(in.bigWig,
### character string path to input bigWig file.
  out.bedGraph,
### character string path to output bedGraph file.
  chrom=NULL,
### character string, chromosome name to filter data.
  start=NULL,
### start position to filter data.
  end=NULL
### end position to filter data.
){
  system.or.stop(bigWigToBedGraphCommand(
    in.bigWig,
    out.bedGraph,
    chrom,
    start,
    end))
}

bigWigToBedGraphCommand <- structure(function
### Get command line to run bigWigToBedGraph.
(in.bigWig,
### character string path to input bigWig file.
  out.bedGraph,
### character string path to output bedGraph file.
  chrom=NULL,
### character string, chromosome name to filter data.
  start=NULL,
### start position to filter data.
  end=NULL
### end position to filter data.
){
  isOK <- function(x)is.atomic(x) && length(x)==1 && !is.na(x)
  paste(
    "bigWigToBedGraph",
    if(isOK(chrom))paste0("-chrom=", chrom),
    if(isOK(start))paste0("-start=", start),
    if(isOK(end))paste0("-end=", end),
    shQuote(in.bigWig),
    shQuote(out.bedGraph))
}, ex=function(){
  PeakSegPipeline::bigWigToBedGraphCommand(
    "in.bigWig", "out.bedGraph", "chr1", 0, 100)
})

readBigWig <- function
### Read part of a bigWig file into R as a data.table (assumes
### bigWigToBedGraph is present on your PATH).
(bigwig.file,
### path or URL of bigwig file.
 chrom=NULL,
### chromosome to read.
 start=NULL,
### position before reading.
 end=NULL
### plain text file where coverage is saved before reading into R.
){
  count <- . <- chromStart <- chromEnd <- NULL
  stopifnot(length(bigwig.file) == 1)
  stopifnot(length(chrom) == 1)
  stopifnot(length(start) == 1)
  stopifnot(length(end) == 1)
  stopifnot(is.character(bigwig.file))
  stopifnot(is.character(chrom))
  start <- as.integer(start)
  end <- as.integer(end)
  stopifnot(0 <= start)
  stopifnot(start < end)
  stopifnot(end < Inf)
  cmd <- PeakSegPipeline::bigWigToBedGraphCommand(
    bigwig.file, "/dev/stdout", chrom, start, end)
  cov.dt <- suppressWarnings({#for 0-row data.
    data.table::fread(
      cmd=cmd,
      drop=1,
      col.names=c("chromStart", "chromEnd", "count"))
  })
  cov.dt
### data.table with columns chromStart chromEnd count.
}

bigWigInfo <- function
### Run bigWigInfo to find chrom sizes.
(bigwig.file
### path or URL of bigwig file.
){
  stopifnot(is.character(bigwig.file))
  stopifnot(length(bigwig.file) == 1)
  chroms <- fread(
    cmd=paste(
      "bigWigInfo",
      shQuote(bigwig.file),
      "-chroms | grep '^\\s'"),
    header=FALSE, sep=" ")
  setnames(chroms, c("chrom", "chrom.int", "chromEnd"))
  chroms$chrom <- sub("\\s*", "", chroms$chrom)
  chroms
}

stop.without.ucsc <- function
### Stop with an error if UCSC command line programs are not
### available.
(prog.vec=c(
  "bigWigInfo", "bigWigToBedGraph",
  "bedToBigBed", "bedGraphToBigWig")
### Vector of command line programs to test via base::Sys.which.
){
  path.vec <- Sys.which(prog.vec)
  if(any(not.found <- path.vec=="")){
    stop(
      "UCSC command line programs not found, or not executable: ",
      paste(prog.vec[not.found], collapse=", "))
  }
  path.vec
### Full paths to programs.
}
