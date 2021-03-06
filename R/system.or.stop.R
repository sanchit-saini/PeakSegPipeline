system.or.stop <- function
### Run a command line and stop with
### an error for non-zero status code.
(cmd,
### Command line arguments, which will be escaped by base::shQuote,
### pasted together, and then passed to system.
  verbose=getOption("PeakSegPipeline.verbose", 1)
### print output?
){
  if(verbose)cat(cmd, "\n")
  silent <- isTRUE(all.equal(verbose, 0))
  code <- system(
    cmd, intern=FALSE, ignore.stdout=silent, ignore.stderr=silent)
  if(code != 0){
    stop("non-zero exit code ", code)
  }
### Nothing.
}
