
plotdat_fun <- function(x, city_name, x_breaks = NULL, y_breaks = NULL){  
  plotdat <- x

  if (is.null(y_breaks)) {
    max_y <- max(plotdat$total_count, na.rm = TRUE)
    y_breaks <- pretty(c(0, max_y), n = 3)
  }
  
  pic <- ggplot(plotdat, aes(x = date)) +
    geom_line(aes(y = total_count, color = "Total Count"), linewidth = 0.4) +
    geom_line(aes(y = fitted_train, color = "Fitted Train"), linewidth = 0.4) +
    geom_ribbon(
      aes(
        ymin = fitted_train_lower_ci,
        ymax = fitted_train_higher_ci
      ),
      fill = "red",
      alpha = 0.5
    ) +
    labs(title = city_name, x = NULL, y = NULL, color = NULL) +
    scale_color_manual(values = c("Total Count" = "gray30", "Fitted Train" = "red")) +
    theme_minimal() +
    scale_y_continuous(
      breaks = y_breaks,
      limits = c(0, max(y_breaks))
    )
  return(pic)
}
