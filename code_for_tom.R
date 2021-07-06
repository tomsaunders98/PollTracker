

library(tidyverse)
library(lubridate)
library(britpol)

dta <- 
  pollbase %>% 
  add_elections(date = "end") %>% 
  filter(last_elec == "2019-12-12")


plot <- 
  dta %>% 
  pivot_longer(
    cols = c("con", "lab", "lib"),
    names_to = "party",
    values_to = "vote"
  ) %>% 
  mutate(
    time = interval(min(end), end)/years(1)
  ) %>% 
  ggplot(
    aes(
      y = vote,
      x = time,
      colour = party,
      fill = party
    )
  ) +
  geom_point(
    alpha = 0.2
  ) +
  stat_smooth(
    method = "loess",
    span = 0.1,
    formula = y ~ x
  )




m1 <-
  brm(formula = 
        bf(con ~ 1 + gb + s(time, k = 10) + (1 | pollster)) +
        bf(lab ~ 1 + gb + s(time, k = 10) + (1 | pollster)) +
        bf(lib ~ 1 + gb + s(time, k = 10) + (1 | pollster)) +
        set_rescor(rescor = TRUE),
      family = gaussian(),
      prior =
        prior(normal(0.4, 0.1), class = "Intercept", resp = "con") +
        prior(normal(0, 0.5), class = "b", resp = "con") +
        prior(exponential(5), class = "sd", resp = "con") +
        prior(exponential(5), class = "sds", resp = "con") +
        prior(exponential(5), class = "sigma", resp = "con") +
        # Repeat for other parties +
        prior(lkj(2), class = "rescor"),
      backend = "cmdstanr",
      data = dta,
      seed = 666,
      iter = 2e3,
      chains = 2,
      cores = 2,
      threads = threading(2),
      refresh = 5,
      adapt_delta = .95,
      max_treedepth = 15,
      file = here("_output", paste0("model", "-", Sys.Date()))
  )

ranef(m1)

