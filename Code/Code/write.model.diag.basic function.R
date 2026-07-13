
write.model.diag.basic <- function(model.list, file) 
{
  model.diag <- get.model.diag.basic(model.list)
  write.csv(model.diag, file=file, row.names=F)
}

get.model.diag.basic <- function(model.list) 
{
  nModel <- length(model.list)
  models <- fmls <- vector(mode="character", length=nModel)
  ubres <- aics <- r.sqs <- dev.expls <- vector(mode="double", length=nModel)
  for (i in 1:nModel) {
    model.name <- names(model.list)[i]
    curModel <- model.list[[model.name]]
    models[i] <- model.name
    fmls[i] <- paste(curModel$formula[2], "~", curModel$formula[3])
    ubres[i] <- curModel$gcv.ubre
    aics[i] <- curModel$aic
    
    if (length(curModel) <= 1) {
      r.sqs[i] <- NA
      dev.expls[i] <- NA
    } else {
      summ <- summary(curModel)
      r.sqs[i] <- ifelse(is.null(summ$r.sq), NA, summ$r.sq) 
      dev.expls[i] <- ifelse(is.null(summ$dev.expl), NA, summ$dev.expl)
    }
  }
  model.diag <- data.frame(Model=models, Formula=fmls, UBRE=ubres, AIC=aics, Adj.R2=r.sqs, DevExpl=dev.expls)
  model.diag
}

