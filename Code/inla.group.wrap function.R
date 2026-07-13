inla.group.wrap <- function(data, breaks) {
  require(dplyr)
  colnames(data)[2] <- "value"
  data$group <- findInterval(data$value, breaks, rightmost.closed=T)
  data.median <- data%>%
    group_by(group)%>%
    dplyr::summarize(var.grp=median(value, na.rm=T))
  data <- merge(data, data.median, by="group")
  data <- data[order(data$ID),]
  data$var.grp
  # data$var.grp
}
