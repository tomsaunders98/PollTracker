library(tidyr)
library(dplyr)
library(tidybayes)
library(lubridate)
library(StanHeaders)
library(rstan)
library(brms)
library(logging)

mc.cores <- parallel::detectCores()

logReset()
basicConfig()
addHandler(writeToFile, file="output.log", level='FINEST')

date <- Sys.Date()
loginfo(paste0("Poll Model started"))


polls_long <- read.csv("polls.csv") %>%
  tibble() %>%
  mutate(
    StartDate = as.Date(StartDate, format = "%d/%m/%Y"),
    EndDate = as.Date(EndDate, format = "%d/%m/%Y"),
    date_long = EndDate - (1 + as.numeric(EndDate-StartDate)) %/% 2, # Midpoint as date val (field dates are so close this is almost pointless)
    date_index = 1 + as.numeric(date_long) - min(as.numeric(date_long)), #bind date index to earliest poll
    Area = as.factor(Area)
  ) 

pdate <- polls_long %>%
  select(date_long, date = date_index)

polls <- polls_long %>%
  select(
    con = Con,
    lab = Lab,
    lib = Lib.Dem,
    snp = SNP,
    grn = Green,
    area = Area,
    date = date_index,
    pollster = Pollster
  ) %>%
  drop_na() %>%
  mutate(
    oth = 1- (con+lab+lib+snp+grn),
  ) %>%
  subset(oth > 0)

npolls <- polls %>%
  mutate(
    outcome = as.matrix(polls[names(polls) %in% c("con", "lab", "lib","snp", "grn", "oth")])
  )



## Fit Model
result <- tryCatch({
  m1 <-
    brm(formula = bf(outcome ~ 1 + area + s(date, k = 10) + (1 | pollster)),
        family = dirichlet(link = "logit", refcat = "oth"),
        prior =
          prior(normal(0, 1.5), class = "Intercept", dpar = "mucon") +
          prior(normal(0, 0.5), class = "b", dpar = "mucon") +
          prior(exponential(2), class = "sd", dpar = "mucon") +
          prior(exponential(2), class = "sds", dpar = "mucon") +
          prior(normal(0, 1.5), class = "Intercept", dpar = "mugrn") +
          prior(normal(0, 0.5), class = "b", dpar = "mugrn") +
          prior(exponential(2), class = "sd", dpar = "mugrn") +
          prior(exponential(2), class = "sds", dpar = "mugrn") +
          prior(normal(0, 1.5), class = "Intercept", dpar = "mulab") +
          prior(normal(0, 0.5), class = "b", dpar = "mulab") +
          prior(exponential(2), class = "sd", dpar = "mulab") +
          prior(exponential(2), class = "sds", dpar = "mulab") +
          prior(normal(0, 1.5), class = "Intercept", dpar = "mulib") +
          prior(normal(0, 0.5), class = "b", dpar = "mulib") +
          prior(exponential(2), class = "sd", dpar = "mulib") +
          prior(exponential(2), class = "sds", dpar = "mulib") +
          prior(normal(0, 1.5), class = "Intercept", dpar = "musnp") +
          prior(normal(0, 0.5), class = "b", dpar = "musnp") +
          prior(exponential(2), class = "sd", dpar = "musnp") +
          prior(exponential(2), class = "sds", dpar = "musnp") +
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
          )
    )
}, error = function(e) {
  logerror(paste0("Model Error: ", e))
}, finally = {
  # always executed after handlers
}
)




max <- 1+as.numeric(max(polls_long$date_long))-min(as.numeric(polls_long$date_long))
pred_dta <-
  tibble(
    date = c(1:max),
    #date = seq(min(polls_long$date_long), max(polls_long$date_long), by = "day"),
    area = "GB"
  )

pred_dta <-
  epred_draws(m1,
    newdata = pred_dta,
    re_formula = NA
  ) %>%
  group_by(date, .category) %>%
  summarise(
    est = median(.epred),
    lower = quantile(.epred, probs = .05),
    upper = quantile(.epred, probs = .95),
    .groups = "drop"
  ) %>%
  ungroup() %>%
  rename(party = .category)



clean_polls <- polls_long %>%
  rename(
    con = Con,
    lab = Lab, 
    lib = Lib.Dem,
    snp = SNP,
    grn = Green
  ) %>%
  pivot_longer(c(con, lab, lib, snp, grn), names_to = "party", values_to="polls") %>%
  select(party, polls, date = date_index, date_long)

pred <- merge(clean_polls, pred_dta, by = c("date", "party")) %>% select(!date) %>%
  group_by(date_long, party) %>%
  summarise(
    polls = mean(polls),
    est = mean(est),
    upper = mean(upper),
    lower = mean(lower)
  ) %>%
  rename(
    date = date_long
  )


all_dates <- seq(min(pred$date, na.rm = T), max(pred$date, na.rm = T), by="days")

missing_dates <- setdiff(all_dates, pred$date)


interpol <- pred %>%
  group_by(party) %>%
  summarise(
    est = approx(x = date, y = est, xout = missing_dates)$y,
    upper = approx(x = date, y = upper, xout = missing_dates)$y,
    lower = approx(x = date, y = lower, xout = missing_dates)$y,
    date = missing_dates
  ) %>%
  mutate(
    date = as.Date(date,origin="1970-01-01")
  )

export <- merge(pred, interpol, by=c("est", "upper", "lower", "date", "party"), all = T) %>%
  arrange(date)

write.csv(export, "pred.csv", row.names = F)




