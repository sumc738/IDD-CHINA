rm(list=ls())
library(mgcv)

##############For example, AD
data.model <- read.csv('<historical_data.csv>')

model.zone.list <- list()
knot <- 4

# basic model, without the zoneVar
model.zone.list$basic <- gam(as.formula(sprintf("total_count ~ s(Temp, k=%d) + s(Pre, k=%d)+pop" , 
                                                knot, knot)), 
                             family = ziP, data=data.model) 


# one zoneVar in turn
zoneVar.list <- c("climate_zone","Ecological_zone","Geomorphic_type", ..."intestinal_protozoa_infection")


##### Best zonalVar selection --  #####
#       y is the disease cases
#       gam with ziP is used!

for (zoneVar in zoneVar.list) {
  s <- Sys.time()
  data.model[,zoneVar] <- as.factor(data.model[,zoneVar])
  gam.zonal <- try(gam(as.formula(sprintf("total_count ~ s(Temp, by=%s, k=%d) + 
                                              s(Pre, by=%s, k=%d)  + factor(%s)+pop", 
                                          zoneVar, knot, zoneVar, knot, zoneVar)), 
                       family=ziP, data=data.model))
  
  if ('try-error' %in% class(gam.zonal)) {
    model.zone.list[[zoneVar]] <- NA
    print(sprintf("model has something wrong"))
  } else {
    e <- Sys.time()
    print(e-s)
    model.zone.list[[zoneVar]] <- gam.zonal
  }
  rm(gam.zonal)
}


write.model.diag.basic(model.zone.list, file=sprintf("./model.zoneVarSelection.diag.k%d_1.0(pop).csv", knot))