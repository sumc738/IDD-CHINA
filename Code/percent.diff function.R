# percent diff by comparing 2023-2100 to 2010-2022
percent.diff <- function(obs, pred) {
  percent <- 0
  if(obs==0) {
    # in case of dividing by zero
    percent <- (pred-obs)/0.001*100
  } else {
    percent <- (pred-obs)/obs *100
  }
  percent
}
