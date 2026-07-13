
library(car)
library(ggtext)
library(reshape2)
library(spdep)
library(rgdal)
library(inlabru)
library(INLA)
library(dplyr)
library(xlsx)
library(splines)
library(MASS)
library(MAVE)
library(plyr)
library(hydroGOF)

##############For example, AD
### Set Working Directory and INLA Options
inla.setOption(inla.mode="experimental")
n.quantile = 20
### List of all climate indices considered in MAVE dimension reduction
var.mave.all <- c("Temp", "TXx", "TNn", "TN10P", "TX10P",...","PRCPTOT")

### Load Spatial Adjacency Matrix and Data
W.City <- inla.read.graph(filename = "<adjacency_matrix>")
data.model <- read.csv('<historical_data.csv>')
city=data.model[!duplicated(data.model$city),]


### Convert Categorical Variables to Factors
### Categorical variable levels
urbanization.levels <- c("1","2","3", "4","5")
bed.levels<- c("1","2","3", "4","5")
climate.levels <- c("1","2","3", "4","5","6","7","8")
cockroach.levels<- c("1","2","3", "4","5","6","7")
# These are the first spatial variable selected from each of the four disease-specific GAM screening panels:
#   urbanization_class: from the socio-economic panel
#   beds_class: from the health-care panel  
#   climate_zone: from the environment and terrain panel
#   cockroach_class: from the biological panel
data.model$urbanization_class <- factor(data.model$urbanization_class, levels=urbanization.levels)
data.model$beds_class <- factor(data.model$beds_class, levels=bed.levels)
data.model$climate_zone <- factor(data.model$climate_zone, levels=climate.levels)
data.model$cockroach_class <- factor(data.model$cockroach_class, levels=cockroach.levels)


### Load MAVE-Reduced Climate Variables and Prepare Modeling Dataset
load('<MAVE_object.RData>')
data.valid <- cbind(data.model, data.x.mave.all)

data.valid$ID <- seq(1, nrow(data.valid))
data.valid$logPop <- log(data.valid$pop)
data.valid$log_gravity_flu <- log(data.valid$gravity_flu)
data.valid$log_radition_flu <- log(data.valid$radition_flu)

### Group MAVE directions into quantiles
data.valid$temp.grp <- inla.group.wrap(data.valid[,c("ID","Temp")], quantile(data.valid$Temp, probs=seq(0, 1, 1/n.quantile)))
data.valid$pre.grp <- inla.group.wrap(data.valid[,c("ID","Pre")], quantile(data.valid$Pre, probs=seq(0, 1, 1/n.quantile)))
for (i in 1:ncol(data.x.mave.all)) {
  data.valid[[sprintf("dir%d.grp",i)]] <- inla.group.wrap(data.valid[,c("ID",sprintf("dir%d",i))], quantile(data.valid[,sprintf("dir%d",i)], probs=seq(0, 1, 1/n.quantile)))
}

data.valid.cv <- data.valid # 2010~2019 for calibration, 2020~2022 for validation
data.valid.cv$cases<-data.valid.cv$total_count
data.valid.cv[data.valid.cv$year > 2019, "total_count"] <- NA
data.valid.cv$CityID=data.valid.cv$CityID+1


##### Model selection #####
### Define Model Formulas
fml.list <- list()

#baseline model
fml.list$Model1 <- total_count ~ -1 + logPop + log_gravity_flu +log_radition_flu +
  f(CityID, model = "bym2", graph = W.City, scale.model = TRUE)  +
  f(month,model = "rw1", cyclic = TRUE )+
  f(year, model = "ar1",constr = TRUE)


#spatial model: baseline model + spatial variables
fml.list$Model2 <- total_count ~ -1 + logPop + log_gravity_flu +log_radition_flu +
  urbanization_class + beds_class + climate_zone + cockroach_class + 
  f(CityID, model = "bym2", graph = W.City, scale.model = TRUE)  +
  f(month,model = "rw1", cyclic = TRUE )+
  f(year, model = "ar1",constr = TRUE)


# climate model: baseline model + climate variables
fml.list$Model3 <- total_count ~ -1 + logPop + log_gravity_flu +log_radition_flu +
  f(dir1.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(dir2.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(dir3.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(dir4.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(dir5.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(dir6.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(dir7.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(dir8.grp, model="rw1",  scale.model=T, diagonal=1e-4) +
  f(CityID, model = "bym2", graph = W.City, scale.model = TRUE)  +
  f(month,model = "rw1", cyclic = TRUE )+
  f(year, model = "ar1",constr = TRUE)


# spatial and climate model: baseline model + climate variables + spatial variables
#......
# final model without dir1
#.......
# final model without gravity_flu


### Fit All Models Using INLA 
obj.inla.modelCV.list <- list()
for (model in names(fml.list)) {
  
  obj.inla.modelCV.list[[model]] <- inla(fml.list[[model]], 
                                         family="zeroinflatednbinomial2",
                                         # family="zeroinflatedpoisson1", family="nbinomial", family="zeroinflatednbinomial2"
                                         #offset = log(pop / 100000),
                                         data = data.valid.cv,
                                         control.predictor = list(compute = TRUE, link = 1),
                                         control.inla = list(strategy = "adaptive", int.strategy = 'eb', cmin = 0),
                                         control.compute = list(dic = TRUE, cpo = TRUE, waic = TRUE, openmp.strategy = "huge"),
                                         control.fixed = list(prec = 1, prec.intercept = 1),
                                         num.threads = 14)
  
}
save(obj.inla.modelCV.list,   
         file = file.path("J:/IDD/DATA/AD/Results",filename="Model_INLA_CV.RData) )

##### END of model selection ####
