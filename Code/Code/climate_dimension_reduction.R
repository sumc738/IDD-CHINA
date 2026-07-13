library(MAVE)
library(dplyr)
library(forecast)
library(MASS)


########### read data###############
##############For example, AD
data.model <- read.csv('<historical_data.csv>')

######## Extract the dependent variable and the independent variable ##################
var.mave.all <- c("Temp", "TXx", "TNn", "TN10P", "TX10P", ..., "PRCPTOT")
data.model.mave <- data.model[,var.mave.all]
data.model.mean <- matrix(apply(data.model.mave, 2, mean), nrow=1) 
data.model.sd <- matrix(apply(data.model.mave, 2, sd), nrow=1)
data.whole <- data.model.mave


data_model_2023_2100 <- read.csv("<path_to_future_climate_data>/2023-2100climate.csv")

data.whole <- rbind(data.whole,data_model_2023_2100)
data.whole <- (data.whole - data.model.mean[rep(1, times=nrow(data.whole)),]) / data.model.sd[rep(1, times=nrow(data.whole)),]
data.whole.min <- matrix(apply(data.whole, 2, min), nrow=1)


######Extract the independent variable matrix##################
data.x <- as.matrix(data.model.mave)
mave.info <- list(eps=0.1)

for (i in 1:length(var.mave.all)) {
  var <- var.mave.all[i]
  
  ## data normalization
  data.x[,i] <- (data.x[,i] - data.model.mean[i]) / data.model.sd[i]
  
  ## box-cox transformation
  data.x[,i] <- data.x[,i] - data.whole.min[i] + mave.info$eps
  b <- boxcox(data.x[,i]~1) 
  lambda <- b$x[which(b$y==max(b$y))]
  data.x[,i] = (data.x[,i]^lambda-1)/lambda
  mave.info[[var]] <- list(var.mean=data.model.mean[i], var.sd=data.model.sd[i], var.min=data.whole.min[i], lambda=lambda)
}

data.y <- as.vector(data.model$total_count)

dr.mave.all <- mave(data.y ~ data.x)
dr.mave.dim.all <- mave.dim(dr.mave.all)
data.x.mave.all <- mave.data(dr.mave.dim.all, data.x)

save(dr.mave.all, dr.mave.dim.all, data.x.mave.all, mave.info,file=sprintf("./obj.mave.2011-2021.all.%s_new.RData", "MAVE"))
