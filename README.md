[![Build Status](https://travis-ci.org/UofABioinformaticsHub/ngsReports.svg?branch=master)](https://travis-ci.org/UofABioinformaticsHub/ngsReports.svg?branch=master)

# ngsReports

An R Package for managing FastQC reports and other NGS related log files inside R.
This branch is compatible with Bioconductor >= 3.7 only. To install this package using Bioconductor <= 3.6 (R <= 3.4.4) please use the drop down menu above to change to the branch Bioc3.6, and follow the instructions there.

## Installation
To install required packages follows the instructions below.
Currently you need to install the fastqcTheoreticalGC package separately.

```
source("https://bioconductor.org/biocLite.R")
biocLite(c("BiocGenerics", "BiocStyle", "BSgenome", "checkmate", "devtools", "ggdendro",  "plotly", "reshape2", "Rsamtools", "scales", "ShortRead", "tidyverse",  "viridis", "viridisLite", "zoo"))
devtools::install_github('mikelove/fastqcTheoreticalGC')
devtools::install_github('UofABioinformaticsHub/ngsReports', build_vignettes = FALSE)
library(ngsReports)
```

## ShinyApp

A Graphical User Interface (Shiny App) has been developed for interactive inspection of many FastQC reports. The ngsReports shiny app can be installed [here](https://github.com/UofABioinformaticsHub/ngsReports-shinyApp).

# Vignette

The vignette for usage is [here](https://uofabioinformaticshub.github.io/ngsReports/vignettes/ngsReportsIntroduction)


# Citation 

Please cite our [preprint](https://www.biorxiv.org/content/early/2018/05/02/313148):

```
@article{ward2018ngsreports,
  title={ngsReports: An R Package for managing FastQC reports and other NGS related log files.},
  author={Ward, Christopher M and To, Hien and Pederson, Stephen M},
  journal={bioRxiv},
  pages={313148},
  year={2018},
  publisher={Cold Spring Harbor Laboratory}
}
```
