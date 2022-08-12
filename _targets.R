options(tidyverse.quiet = TRUE,
        dplyr.summarise.inform = FALSE)

library(targets)
library(tarchetypes)
library(tidyverse)

tar_option_set(
  packages = c("tibble"),
  format = "rds"
)

# here::here() returns an absolute path, which then gets stored in tar_meta and
# becomes computer-specific (i.e. /Users/andrew/Research/blah/thing.Rmd).
# There's no way to get a relative path directly out of here::here(), but
# fs::path_rel() works fine with it (see
# https://github.com/r-lib/here/issues/36#issuecomment-530894167)
here_rel <- function(...) {fs::path_rel(here::here(...))}

# Load functions for the pipeline
source("R/triptych.R")


# THE MAIN PIPELINE ----
list(
  ## Create the three panel Bayesian plot ----
  tar_target(bayesian_triptych, build_triptych_panels()),

  ## Build the README ----
  tar_target(workflow_graph, tar_mermaid(targets_only = TRUE, outdated = FALSE,
                                         legend = FALSE, color = FALSE)),
  tar_quarto(readme, here_rel("README.qmd")),

  ## Build site ----
  tar_quarto(site, path = ".")
)
