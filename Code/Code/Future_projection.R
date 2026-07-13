##### Prediction for future #####
library(car)
library(ggplot2)
library(ggtext)
library(reshape2)
library(spdep)
#library(rgdal)
library(inlabru)
library(INLA)
library(dplyr)
library(xlsx)
library(splines)
library(MASS)
library(MAVE)
library(plyr)

##############For example, AD
n.quantile <- 20

#### Define future scenarios
scenario.list <- c("SSP126","SSP245","SSP370","SSP585")
pattern.list <- c("IPSL-CM6A-LR","NorESM2-MM","MPI-ESM1-2-HR","MRI-ESM2-0","CMCC-ESM2")  
popS.list <- c("SSP1","SSP2","SSP3")


var.mave.all <- c("Temp", "TXx", "TNn", "TN10P", "TX10P",...,"PRCPTOT")

var.inla <- c("city", "CityID", "year", "month", "total_count", "pop","gravity_flu","radition_flu",
              "urbanization_class", "beds_class", "climate_zone","cockroach_class",
              "Temp", "Pre")

##### read data
W.City <- inla.read.graph(filename = "<adjacency_matrix>")
data.model <- read.csv('<historical_data.csv>')
load('<MAVE_object.RData>')


####Prediction for future
fml.list <- list()
fml.list$Best_fit <- fml.best

setwd("<path_to_future_data_directory>")
obj.inla.list <- list()

#### MAVE transformation function
for (scenario in scenario.list) {
  for (pattern in pattern.list) {

# Load future climate data for this scenario-GCM combination
    cat(sprintf("reading future data: %s_%s_processed.csv...\n", scenario, pattern))
    data.future <- read.csv(sprintf("./%s_%s_processed.csv", scenario, pattern))
   
    data.future$total_count <- NA
    cat(sprintf("data transformation based on mave coefs for %s_%s:\n", scenario, pattern))
    data.future.mave <- as.matrix(rbind(data.model[,var.mave.all], data.future[,var.mave.all]))

 # Apply MAVE transformation
    for (i in 1:length(var.mave.all)) {
      var <- var.mave.all[i]
      data.future.mave[,i] <- (data.future.mave[,i] - mave.info[[var]]$var.mean) / mave.info[[var]]$var.sd
      data.future.mave[,i] <- data.future.mave[,i] - mave.info[[var]]$var.min + mave.info$eps
      lambda <- mave.info[[var]]$lambda
      data.future.mave[,i] <- (data.future.mave[,i]^lambda-1)/lambda
      cat(sprintf("          %s\n", var))
    }
    data.future.mave <- mave.data(dr.mave.dim.all, data.future.mave)
    
    for (s in popS.list) {
      data.future$pop<-NA
      base_vars <- c("gravity_flu", "radition_flu")
      target_vars <- paste0(base_vars, "_", s)
      var.inla2 <- c("city", "CityID", "year", "month", "total_count", s,target_vars,
                     "urbanization_class", "beds_class", "climate_zone","cockroach_class",
                     "Temp", "Pre")
      
      temp <- data.future[, var.inla2]
      colnames(temp) <- var.inla
      data.future.cur <- cbind(rbind(data.model[,var.inla], temp), data.future.mave)
      
      #####Variable Preparation
      data.future.cur$logPop <- log(data.future.cur$pop)
      data.future.cur$log_gravity_flu <- log(data.future.cur$gravity_flu)
      data.future.cur$log_radition_flu <- log(data.future.cur$radition_flu)
      
      data.future.cur$ID <- seq(1, nrow(data.future.cur))
      data.future.cur$CityID=data.future.cur$CityID+1

      ### Group MAVE directions into quantiles
      for (i in 1:ncol(data.x.mave.all)) {
        data.future.cur[[sprintf("dir%d.grp",i)]] <- inla.group.wrap(data.future.cur[,c("ID",sprintf("dir%d",i))], quantile(data.future.cur[,sprintf("dir%d",i)], probs=seq(0, 1, 1/n.quantile)))
      }

      cat(sprintf("start model fitting and prediction for %s_%s_%s...\n", scenario, pattern, s))
      
      ###Inla predicting
      obj.inla <- inla(fml.best, 
                      family="zeroinflatednbinomial2",
                       data=data.future.cur,
                       control.predictor=list(compute=T, link=1),
                       control.inla=list(strategy="adaptive", int.strategy='eb', cmin=0),
                       control.compute=list(openmp.strategy="huge"),
                       control.fixed=list(prec=1, prec.intercept=1),
                       num.threads=14)
      
      data.future.cur$Pred <- obj.inla$summary.fitted.values$mean
      save(obj.inla.list, file=sprintf("obj.inla_%s_%s_%s_new.RData", scenario, pattern, s))
    } 
  }
}
