# IDD-CHINA

> Code repository for: **"Asymmetric expansion of infectious diarrhoeal disease risk in China under climate change"**
>
> Dai T, Liu J, Zhou J, Zheng R, Wang X, Zhang L, Lu F, Tian L, Pei S, Zhou H\*, Guo P\*.

---

## Overview

This repository contains the R code for a hierarchical spatiotemporal modelling framework that projects the burden of six major infectious diarrhoeal diseases (IDDs) — amoebic dysentery, bacillary dysentery, typhoid fever, paratyphoid fever, cholera, and other infectious diarrhoea — across 365 cities in mainland China from 2023 to 2100 under coupled climate–population scenarios.

The analysis integrates:
- **15.6 million cases** from monthly city-level surveillance data (2010–2022),
- **29 climate variables** with emphasis on extreme temperature and precipitation indices,
- **Five CMIP6 models** under four Shared Socioeconomic Pathways (SSP1–2.6, SSP2–4.5, SSP3–7.0, SSP5–8.5),
- **Three population projections**, yielding **60 ensemble combinations**.

Bayesian spatiotemporal models with Besag–York–Mollié (BYM2) spatial random effects were fitted using **Integrated Nested Laplace Approximation (INLA)**, combined with **MAVE**-based climate dimension reduction.

---

## Data sources

| Data type | Description |
|-----------|-------------|
| Disease surveillance | Monthly IDD case counts for 365 Chinese cities (2010–2022), aggregated to six pathogen-specific categories |
| Climate variables | 29 indices including extreme temperature (TXx, TNn, TN10P, TX10P) and precipitation (PRCPTOT, etc.), from CN05.1 observations and CMIP6 projections |
| Spatial adjacency | City-level spatial neighbourhood matrix for BYM2 random effects |
| Population | City-level population data and three SSP-aligned population projections |


> **Note**: Raw surveillance data are not publicly deposited due to data-sharing restrictions. Data access requests should be directed to the corresponding authors. Processed climate and population inputs are described in the manuscript.

---

## Methods

1. **Spatial variable screening** — Disease-specific GAMs (zero-inflated Poisson, `mgcv::ziP`) screen candidate covariates across four thematic panels: socio-economic, health-care, environment/terrain, and biological.
2. **Climate dimension reduction** — **MAVE** (Minimum Average Variance Estimation) compresses high-dimensional climate indices into low-dimensional directions; quantile grouping (`inla.group.wrap`) prepares them for INLA.
3. **Bayesian spatiotemporal model (INLA)** — Response distribution: zero-inflated negative binomial 2. Model components:
   - City-level random effect with BYM2 spatial structure (`f(CityID, model="bym2", graph=W.City)`),
   - Cyclic monthly random walk (`f(month, model="rw1", cyclic=TRUE)`),
   - AR1 yearly trend (`f(year, model="ar1")`),
   - Population size and population mobility (gravity/radiation) covariates.
   - Model selection via DIC / WAIC / CPO.
4. **Future projection** — Best-fitting model applied to 60 SSP × GCM × population combinations (2023–2100).
5. **Scenario analysis** — Mann–Kendall trend tests (`trend::sens.slope`) assess city-level temporal trends and relative changes under each scenario.

---

## Repository structure

```
IDD-CHINA/
├── Code/
│   ├── modeling.R                      # INLA model fitting and cross-validation
│   ├── spatial_variable_selection.R    # GAM(ziP)-based spatial variable screening
│   ├── climate_dimension_reduction.R   # MAVE climate dimension reduction
│   ├── Future_projection.R             # Future SSP × GCM scenario projections
│   ├── future_scenario_analysis.R      # Scenario trend analysis and city-level summaries
│   ├── fit_plot.R                      # Model fit and projection visualisation
│   ├── sankey_plot_function.R          # Sankey diagram (population flow → infection)
│   ├── inla.group.wrap function.R      # INLA quantile grouping helper
│   ├── recode.exprs function.R         # Factor recoding utility
│   ├── sens.recode function.R          # Trend significance classification
│   ├── percent.diff function.R         # Relative difference computation
│   └── write.model.diag.basic function.R  # Model diagnostics output
├── LICENSE                             # Unlicense (public domain)
└── README.md
```

---

## Environment & dependencies

- **Language**: R (≥ 4.0)

```r
install.packages(c("car", "ggtext", "reshape2", "spdep", "rgdal", "inlabru",
                   "dplyr", "xlsx", "splines", "MASS", "MAVE", "plyr",
                   "hydroGOF", "trend", "ggplot2", "mgcv"))
# INLA must be installed from the official source (not CRAN):
install.packages("INLA", repos = "https://inla.r-inla-download.org/R/stable")
```

- **Hardware**: Some scripts use `num.threads = 14`; adjust to your machine. Large matrix operations may require substantial RAM.

---

## Usage

> ⚠️ Data paths in the scripts are currently hard-coded absolute paths (e.g., `J:/IDD/DATA/...`). Before running, replace them with paths to your local data directory.

```r
# 1. Set working directory
setwd("<project_root>/Code")

# 2. Spatial variable screening
source("spatial_variable_selection.R")

# 3. Climate dimension reduction (generates MAVE .RData objects)
source("climate_dimension_reduction.R")

# 4. INLA model fitting and cross-validation
source("modeling.R")

# 5. Future scenario projections (requires processed SSP × GCM inputs)
source("Future_projection.R")

# 6. Scenario trend analysis
source("future_scenario_analysis.R")
```

---

## License

The code is released under the **Unlicense** (public domain; see `LICENSE` file). It may be freely used for any purpose. When used in academic publications, please cite this repository and the corresponding paper.

---

## Code availability

The code is publicly available at [https://github.com/TingtDai12/IDD-CHINA](https://github.com/TingtDai12/IDD-CHINA) under the Unlicense. Raw surveillance data are not publicly shareable; access requests should be directed to the corresponding authors (H.Z. and P.G.).
