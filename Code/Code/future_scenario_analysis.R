library(dplyr)
library(trend)
library(xlsx)


##### Data preparation #####
data.model <- read.csv("J:/IDD/DATA/AD/Modeling/10-22ad_city_year_month_order.csv")
data.pred.whole <- read.csv("J:/IDD/DATA/AD/Results/Predict_data.csv")


##### Spatial pattern for risk evaluation #####
data.pred.whole.city <- data.pred.whole%>%
  group_by(CityID, city,year, Scenario, Pattern, popS)%>%
  dplyr::summarize(Pred.sum=sum(Pred, na.rm=T)  )  %>%
  
  group_by(CityID,city, year, Scenario)%>%
  dplyr::summarize(Pred.mean=mean(Pred.sum, na.rm=T),
                   Pred.sd=sd(Pred.sum, na.rm=T))


data.model.city <- data.model[, c("CityID","city", "year", "month", "total_count")]
data.model.city <- data.model.city%>%
  group_by(CityID,city, year)%>%
  dplyr::summarize(Pred.mean=sum(total_count, na.rm=T))

data.model.city$CityID=data.model.city$CityID+1
data.model.city$Scenario <- "Observed"
data.model.city$Pred.sd <- 0
data.model.city <- data.model.city[, c("CityID", "city","year", "Scenario", "Pred.mean", "Pred.sd")]
data.pred.whole.city <- rbind(data.model.city, data.pred.whole.city)

info.city <- read.csv("J:/IDD/DATA/Shared_variable/365city_id.csv")
colnames(info.city)[2:5]<-c("city","cid","province","pid")
info.city$CityID=info.city$CityID+1
info.city<-info.city[,c("CityID", "city","cid","province")]

data.pred.whole.city <- merge(info.city, data.pred.whole.city, by=c("CityID","city"))

#data.pred.whole.city$Pred.mean <- round(data.pred.whole.city$Pred.mean) # important!!

data.pred.whole.city$Date <- as.Date(paste(data.pred.whole.city$year, "1", "1", sep="/"))
data.pred.whole.city <- data.pred.whole.city[order(data.pred.whole.city$Scenario, data.pred.whole.city$CityID, data.pred.whole.city$year),]

id.city <- unique(data.pred.whole.city$CityID)
df.city <- data.frame(CityID = vector(mode="integer", length=length(id.city)),
                      SumCase = vector(mode="integer", length=length(id.city)),
                      YearlyCase = vector(mode="double", length=length(id.city)),
                      mean = vector(mode="double", length=length(id.city)),
                      slope = vector(mode="double", length=length(id.city)),
                      p = vector(mode="double", length=length(id.city)),
                      level = vector(mode="integer", length=length(id.city)),
                      percDiff = vector(mode="double", length=length(id.city)),
                      mean_126 = vector(mode="double", length=length(id.city)),
                      mean_245 = vector(mode="double", length=length(id.city)),
                      mean_370 = vector(mode="double", length=length(id.city)),
                      mean_585 = vector(mode="double", length=length(id.city)),
                      slope_126 = vector(mode="double", length=length(id.city)),
                      slope_245 = vector(mode="double", length=length(id.city)),
                      slope_370 = vector(mode="double", length=length(id.city)),
                      slope_585 = vector(mode="double", length=length(id.city)),
                      p_126 = vector(mode="double", length=length(id.city)),
                      p_245 = vector(mode="double", length=length(id.city)),
                      p_370 = vector(mode="double", length=length(id.city)),
                      p_585 = vector(mode="double", length=length(id.city)),
                      level_126 = vector(mode="integer", length=length(id.city)),
                      level_245 = vector(mode="integer", length=length(id.city)),
                      level_370= vector(mode="integer", length=length(id.city)),
                      level_585= vector(mode="integer", length=length(id.city)),
                      percDiff_126 = vector(mode="double", length=length(id.city)),
                      percDiff_245 = vector(mode="double", length=length(id.city)),
                      percDiff_370 = vector(mode="double", length=length(id.city)),
                      percDiff_585 = vector(mode="double", length=length(id.city))) 


for (i in 1:length(id.city)) {
  case.city.obs <- data.pred.whole.city[data.pred.whole.city$CityID==id.city[i] &
                                          data.pred.whole.city$Scenario=="Observed" &
                                          data.pred.whole.city$year<=2022, "Pred.mean"]
  case.city.pred.126 <- data.pred.whole.city[data.pred.whole.city$CityID==id.city[i] &
                                               data.pred.whole.city$Scenario=="SSP126" &
                                               data.pred.whole.city$year>2022, "Pred.mean"]
  case.city.pred.245 <- data.pred.whole.city[data.pred.whole.city$CityID==id.city[i] &
                                               data.pred.whole.city$Scenario=="SSP245" &
                                               data.pred.whole.city$year>2022, "Pred.mean"]
  case.city.pred.370 <- data.pred.whole.city[data.pred.whole.city$CityID==id.city[i] &
                                               data.pred.whole.city$Scenario=="SSP370" &
                                               data.pred.whole.city$year>2022, "Pred.mean"]
  case.city.pred.585 <- data.pred.whole.city[data.pred.whole.city$CityID==id.city[i] &
                                               data.pred.whole.city$Scenario=="SSP585" &
                                               data.pred.whole.city$year>2022, "Pred.mean"]
  case.city.pred <- (case.city.pred.126 + case.city.pred.245 + case.city.pred.370 + case.city.pred.585)/4
 
  sens.city.126 <- sens.slope(ts(case.city.pred.126, start=2023, end=2100, frequency=1))
  sens.city.245 <- sens.slope(ts(case.city.pred.245, start=2023, end=2100, frequency=1))
  sens.city.370 <- sens.slope(ts(case.city.pred.370, start=2023, end=2100, frequency=1))
  sens.city.585 <- sens.slope(ts(case.city.pred.585, start=2023, end=2100, frequency=1))
  sens.city <- sens.slope(ts(case.city.pred, start=2023, end=2100, frequency=1))
  
  df.city$CityID[i] <- id.city[i]
  df.city$SumCase[i] <- sum(case.city.obs)
  df.city$YearlyCase[i] <- mean(case.city.obs)
  
  df.city$mean[i] <- mean(c(case.city.pred.126, case.city.pred.245, case.city.pred.370, case.city.pred.585))
  df.city$mean_126[i] <- mean(case.city.pred.126)
  df.city$mean_245[i] <- mean(case.city.pred.245)
  df.city$mean_370[i] <- mean(case.city.pred.370)
  df.city$mean_585[i] <- mean(case.city.pred.585)
  
  df.city$slope[i] <- sens.city$estimates
  df.city$slope_126[i] <- sens.city.126$estimates
  df.city$slope_245[i] <- sens.city.245$estimates
  df.city$slope_370[i] <- sens.city.370$estimates
  df.city$slope_585[i] <- sens.city.585$estimates
  
  df.city$p[i] <- sens.city$p.value
  df.city$p_126[i] <- sens.city.126$p.value
  df.city$p_245[i] <- sens.city.245$p.value
  df.city$p_370[i] <- sens.city.370$p.value
  df.city$p_585[i] <- sens.city.585$p.value
  
  # assign the level fields
  df.city$level[i] <- sens.recode(df.city$slope[i], df.city$p[i])
  df.city$level_126[i] <- sens.recode(df.city$slope_126[i], df.city$p_126[i])
  df.city$level_245[i] <- sens.recode(df.city$slope_245[i], df.city$p_245[i])
  df.city$level_370[i] <- sens.recode(df.city$slope_370[i], df.city$p_370[i])
  df.city$level_585[i] <- sens.recode(df.city$slope_585[i], df.city$p_585[i])
  
  df.city$percDiff[i] <- percent.diff(df.city$YearlyCase[i], df.city$mean[i])
  df.city$percDiff_126[i] <- percent.diff(df.city$YearlyCase[i], df.city$mean_126[i])
  df.city$percDiff_245[i] <- percent.diff(df.city$YearlyCase[i], df.city$mean_245[i])
  df.city$percDiff_370[i] <- percent.diff(df.city$YearlyCase[i], df.city$mean_370[i])
  df.city$percDiff_585[i] <- percent.diff(df.city$YearlyCase[i], df.city$mean_585[i])
}

df.city<-merge(info.city, df.city, by="CityID")