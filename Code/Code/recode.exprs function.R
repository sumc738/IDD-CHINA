###define recode.exprs function

recode.exprs <- function(var, levels=c())
{
  if (length(levels)==0) {
    var.unique <- sort(unique(var))
  } else {
    var.unique <- levels
  }
  exprs <- paste(sprintf("'%s'=%d", var.unique, seq(1,length(var.unique))), sep="", collapse=";")
  exprs
}