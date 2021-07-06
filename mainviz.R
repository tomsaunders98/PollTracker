library(tidyverse)
library(patchwork)
library(tidybayes)
library(lubridate)
library(StanHeaders)
library(rstan)
library(brms)
library(here)



polls <- read.csv("polls.csv") %>%
  tibble() %>%
  mutate(
    StartDate = as.Date(StartDate, format = "%d/%m/%Y"),
    EndDate = as.Date(EndDate, format = "%d/%m/%Y"),
    date_long = EndDate - (1 + as.numeric(EndDate-StartDate)) %/% 2, # Midpoint as date val (field dates are so close this is almost pointless)
    date_index = 1 + as.numeric(date_long) - min(as.numeric(date_long)), #bind date index to earliest poll
    Area = as.factor(Area)
  ) %>%
  select(
    con = Con,
    lab = Lab,
    lib = Lib.Dem,
    #snp = SNP,
    #grn = Green,
    area = Area,
    date = date_index,
    pollster = Pollster
  ) %>%
  mutate(
    oth = 1- (con+lab+lib),
  ) 

npolls <- polls %>%
  mutate(
    outcome = as.matrix(polls[names(polls) %in% c("con", "lab", "lib",  "oth")])
  )



## Fit Model

m1 <-
  brm(formula = bf(outcome ~ 1 + area + s(date, k = 10) + (1 | pollster)),
      family = dirichlet(link = "logit", refcat = "oth"),
      prior =
        prior(normal(0, 1.5), class = "Intercept", dpar = "mucon") +
        prior(normal(0, 0.5), class = "b", dpar = "mucon") +
        prior(exponential(2), class = "sd", dpar = "mucon") +
        prior(exponential(2), class = "sds", dpar = "mucon") +
        # prior(normal(0, 1.5), class = "Intercept", dpar = "mugrn") +
        # prior(normal(0, 0.5), class = "b", dpar = "mugrn") +
        # prior(exponential(2), class = "sd", dpar = "mugrn") +
        # prior(exponential(2), class = "sds", dpar = "mugrn") +
        prior(normal(0, 1.5), class = "Intercept", dpar = "mulab") +
        prior(normal(0, 0.5), class = "b", dpar = "mulab") +
        prior(exponential(2), class = "sd", dpar = "mulab") +
        prior(exponential(2), class = "sds", dpar = "mulab") +
        prior(normal(0, 1.5), class = "Intercept", dpar = "mulib") +
        prior(normal(0, 0.5), class = "b", dpar = "mulib") +
        prior(exponential(2), class = "sd", dpar = "mulib") +
        prior(exponential(2), class = "sds", dpar = "mulib") +
        # prior(normal(0, 1.5), class = "Intercept", dpar = "musnp") +
        # prior(normal(0, 0.5), class = "b", dpar = "musnp") +
        # prior(exponential(2), class = "sd", dpar = "musnp") +
        # prior(exponential(2), class = "sds", dpar = "musnp") +
        prior(gamma(1, 0.01), class = "phi"),
      backend = "rstan",
      data = npolls,
      seed = 666,
      iter = 2e3,
      chains = 4,
      cores = 4,
      refresh = 5,
      control =
        list(
          adapt_delta = .95,
          max_treedepth = 15
        ),
      file = here("_output", paste0("model", "-", Sys.Date()))
  )
