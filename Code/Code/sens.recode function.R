sens.recode <- function(slope, p.value, p.sig=0.05) {
  code <- 9999
  if (slope>0 & p.value<p.sig) {
    code <- 1
  } else if (slope<0 & p.value<p.sig) {
    code <- -1
  } else {
    code <- 0
  }
  code
}