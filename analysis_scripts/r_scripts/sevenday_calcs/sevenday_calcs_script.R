# yadkin 7-day min and max flow calcs

# ---- 1. set up -----

# clear ws
rm(list = ls())

# load libraries
library(tidyverse)
library(lubridate)
library(tibbletime)
library(dplyr)

# load home-made functions 
functions_path="/Users/ssaia/Google Drive/STOTEN/data_and_scripts/stoten_scripts/functions/"
source(paste0(functions_path,"cumul_freq_obs_dist.R"))
source(paste0(functions_path,"cumul_freq_sim_dist.R"))
source(paste0(functions_path,"remove_outliers.R"))
source(paste0(functions_path,"logpearson3_factor_calc.R"))

# load in observed data
# (separated ObsSimQ3Gages.xlsx into obs and sim)
setwd("/Users/ssaia/Google Drive/STOTEN/data_and_scripts/observed_data/streamflow")
obs_data <- read_csv("obs_outlet_streamflow.csv") %>%
  transmute(date = as_date(date_yyyymmdd), observed_q_cms = observed_q_cms) %>%
  filter(year(date) < 2003)

# load in simulated data
# (separated ObsSimQ3Gages.xlsx into obs and sim)
setwd("/Users/ssaia/Google Drive/STOTEN/data_and_scripts/simulated_data/validation_swat_outputs")
sim_data <- read.csv("sim_outlet_streamflow.csv")  %>%
  transmute(date = as_date(date_yyyymmdd), simulated_q_cms = simulated_q_cms) %>%
  filter(year(date) < 2003)

# here obs and sim refer to the observed baseline data from the usgs gage (= obs) and
# the swat simulated data (= sim)

# merge datasets
data <- left_join(obs_data, sim_data, by = "date")

# load kn table
setwd("/Users/ssaia/Google Drive/STOTEN/data_and_scripts/stoten_scripts")
kn_table <- read.csv("kn_table_appendix4_usgsbulletin17b.csv") 


# ---- 2. calculate 7-day max and min ----

# make max and min functions with rollify
max_7_day <- rollify(max, window = 1)
min_7_day <- rollify(min, window = 1)

# 7-day max calcs
obs_data_7_day_max_calcs <- obs_data %>%
  mutate(year = year(date),
         max_q_cms = max_7_day(observed_q_cms)) %>%
  na.omit() %>%
  select(year, max_q_cms)

sim_data_7_day_max_calcs <- sim_data %>%
  mutate(year = year(date),
         max_q_cms = max_7_day(simulated_q_cms)) %>%
  na.omit() %>%
  select(year, max_q_cms)

# 7-day min calcs
obs_data_7_day_min_calcs <- obs_data %>%
  mutate(year = year(date),
         min_q_cms = min_7_day(observed_q_cms)) %>%
  na.omit() %>%
  select(year, min_q_cms)

sim_data_7_day_min_calcs <- sim_data %>%
  mutate(year = year(date),
         min_q_cms = min_7_day(simulated_q_cms)) %>%
  na.omit() %>%
  select(year, min_q_cms)


# ---- 3. calculate observed and simulated cumulative frequency distributions ----

# obs and sim at start of variable name refer to whether data was from usgs gage or swat simulation
# obs and sim at end of variable name refers to whether the result represents an observation 
# (shown as point on distribution figure) or simulation/model (shown as line on distribution figure)

# 7-day max observed distribution (high flows)
obs_data_7_day_max_obsdist <- cumul_freq_obs_dist(obs_data_7_day_max_calcs, flow_option = "high") %>%
  mutate(data_type = "obs")
sim_data_7_day_max_obsdist <- cumul_freq_obs_dist(sim_data_7_day_max_calcs, flow_option = "high") %>%
  mutate(data_type = "sim")

# 7-day min observed distribution (low flows)
obs_data_7_day_min_obsdist <- cumul_freq_obs_dist(obs_data_7_day_min_calcs, flow_option = "low") %>%
  mutate(data_type = "obs")
sim_data_7_day_min_obsdist <- cumul_freq_obs_dist(sim_data_7_day_min_calcs, flow_option = "low") %>%
  mutate(data_type = "sim")

# probability list
my_model_p_list=c(0.99,0.95,0.9,0.8,0.7,0.6,0.5,0.4,0.2,0.1,0.08,0.06,0.04,0.03,0.02,0.01)

# 7-day max simulated distribution (high flows, use observed distribution)
obs_data_7_day_max_simdist <- cumul_freq_sim_dist(obs_data_7_day_max_obsdist, kn_table, my_model_p_list, flow_option = "high") %>%
  mutate(data_type = "obs")
sim_data_7_day_max_simdist <- cumul_freq_sim_dist(sim_data_7_day_max_obsdist, kn_table, my_model_p_list, flow_option = "high") %>%
  mutate(data_type = "sim")

# 7-day min simulated distribution (low flows, use observed distribution)
obs_data_7_day_min_simdist <- cumul_freq_sim_dist(obs_data_7_day_min_obsdist, kn_table, my_model_p_list, flow_option = "low") %>%
  mutate(data_type = "obs")
sim_data_7_day_min_simdist <- cumul_freq_sim_dist(sim_data_7_day_min_obsdist, kn_table, my_model_p_list, flow_option = "low") %>%
  mutate(data_type = "sim")

# merge
obs_cumul_freq_dist_7_day_max_results <- rbind(obs_data_7_day_max_obsdist, obs_data_7_day_max_simdist)
sim_cumul_freq_dist_7_day_max_results <- rbind(sim_data_7_day_max_obsdist, sim_data_7_day_max_simdist)
cumul_freq_dist_7_day_max_results <- rbind(obs_cumul_freq_dist_7_day_max_results, sim_cumul_freq_dist_7_day_max_results)

obs_cumul_freq_dist_7_day_min_results <- rbind(obs_data_7_day_min_obsdist, obs_data_7_day_min_simdist)
sim_cumul_freq_dist_7_day_min_results <- rbind(sim_data_7_day_min_obsdist, sim_data_7_day_min_simdist)
cumul_freq_dist_7_day_min_results <- rbind(obs_cumul_freq_dist_7_day_min_results, sim_cumul_freq_dist_7_day_min_results)


# ---- 4. save model comparison for 10-year and 100-year events ----

cumul_freq_dist_7_day_max_results_comparison <- cumul_freq_dist_7_day_max_results %>%
  filter(dist_type == "model") %>%
  filter(return_period_yr == 10.0 | return_period_yr == 100.0) %>%
  select(-dist_type, -max_annual_logq_logcms) %>%
  spread(key = data_type, value = max_annual_q_cms) %>%
  group_by(return_period_yr) %>%
  mutate(perc_change = ((sim - obs)/obs)*100) %>%
  select(return_period_yr, obs_7_day_max_annual_q_cms = obs, sim_7_day_max_annual_q_cms = sim, perc_change)

cumul_freq_dist_7_day_min_results_comparison <- cumul_freq_dist_7_day_min_results %>%
  filter(dist_type == "model") %>%
  na.omit() %>%
  filter(as.integer(return_period_yr) == 10 | as.integer(return_period_yr) == 99) %>% # not sure why this doesn't work like above
  select(-dist_type, -min_annual_logq_logcms) %>%
  spread(key = data_type, value = min_annual_q_cms) %>%
  group_by(return_period_yr) %>%
  mutate(perc_change = ((sim - obs)/obs)*100) %>%
  select(return_period_yr, obs_7_day_min_annual_q_cms = obs, sim_7_day_min_annual_q_cms = sim, perc_change)


# ---- 5. check graphically ----

# check hydrograph (simulation in red)
ggplot() +
  geom_line(data = obs_data, aes(x = date, y = observed_q_cms)) +
  geom_line(data = sim_data, aes(x = date, y = simulated_q_cms), color = "red")
# simulation tends to miss peaks but that's pretty typical for these models

# check sim vs obs plot (simulation in red)
my_lm <- lm(simulated_q_cms ~ observed_q_cms, data = data)
summary(my_lm)
ggplot() +
  geom_point(data = data, aes(x = observed_q_cms, y = simulated_q_cms), size = 2) +
  xlab("Simulated Q (cms)") +
  ylab("Observed Q (cms)") +
  xlim(0,4000) +
  ylim(0,4000) +
  geom_abline(intercept = 0, slope = 1, lty = 2) +
  geom_abline(intercept = 68.95998, slope = 0.62965, color = "red") +
  theme_bw() +
  theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),
        panel.background=element_blank(),text=element_text(size=18))

# 7-day max
setwd("/Users/ssaia/Google Drive/STOTEN/data_and_scripts/stoten_scripts/script_outputs")
cairo_pdf("7_day_max_dist_comparison.pdf", width = 10, height = 10)
ggplot() +
  geom_point(data = cumul_freq_dist_7_day_max_results %>% filter(dist_type == "obs"), 
             aes(x = return_period_yr, y = max_annual_q_cms, color = data_type), size = 2) +
  geom_line(data = cumul_freq_dist_7_day_max_results %>% filter(dist_type == "model"),
            aes(x = return_period_yr, y = max_annual_q_cms, color = data_type)) +
  annotate("text", x = 50, y = 1, label = "Actual data shown as points. Log Pearson-III model shown as lines.") +
  xlab("Return Period (years)") +
  ylab("7-day Max Annual Q (cms)") +
  ylim(0, 5000) +
  theme_bw() +
  scale_color_manual(name = "Baseline Dataset", labels = c("Observed", "Simulated"), values = c("black", "red")) +
  theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),
        panel.background=element_blank(),text=element_text(size=18),
        legend.position=c(0.75, 0.25))
dev.off()

# 7-day min
setwd("/Users/ssaia/Google Drive/STOTEN/data_and_scripts/stoten_scripts/script_outputs")
cairo_pdf("7_day_min_dist_comparison.pdf", width = 10, height = 10)
ggplot() +
  geom_point(data = cumul_freq_dist_7_day_min_results %>% filter(dist_type == "obs"), 
             aes(x = return_period_yr, y = min_annual_q_cms, color = data_type), size = 2) +
  geom_line(data = cumul_freq_dist_7_day_min_results %>% filter(dist_type == "model"),
            aes(x = return_period_yr, y = min_annual_q_cms, color = data_type)) +
  annotate("text", x = 50, y = 100, label = "Actual data shown as points. Log Pearson-III model shown as lines.") +
  xlab("Return Period (years)") +
  ylab("7-day Min Annual Q (cms)") +
  ylim(-5, 100) +
  theme_bw() +
  scale_color_manual(name = "Baseline Dataset", labels = c("Observed", "Simulated"), values = c("black", "red")) +
  theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),
        panel.background=element_blank(),text=element_text(size=18),
        legend.position=c(0.75, 0.75))
dev.off()

# ---- 6. export results ----

setwd("/Users/ssaia/Google Drive/STOTEN/data_and_scripts/stoten_scripts/script_outputs")
write_csv(cumul_freq_dist_7_day_max_results_comparison, "7_day_max_results.csv")
write_csv(cumul_freq_dist_7_day_min_results_comparison, "7_day_min_results.csv")
