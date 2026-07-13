
plot_sankey <- function(data, var, title = NULL) {
  risk_levels <- c( "High risk","Medium risk", "Low risk", "Minor risk", "No risk")
  
  data <- data %>% 
    mutate(across(all_of(var), as.character))
  
  data_long <- data[, var] %>%
    na.omit() %>%
    make_long(!!!syms(var))
  
  data_long <- data_long %>%
    mutate(node = factor(node, 
                         levels = unique(c(risk_levels, sort(unique(node)[!(unique(node) %in% risk_levels)])))))
  
  p <- ggplot(data_long, aes(x = x, 
                             next_x = next_x, 
                             node = node, 
                             next_node = next_node,
                             fill = node,
                             label = node)) +
    geom_sankey(flow.alpha = 0.5, node.color = "grey20",node.linewidth =0.5) +
    theme_sankey(base_size = 16) +
    labs(
      title = title,
      x = ''
    ) +
    scale_fill_viridis_d()
  
  return(p)
}
