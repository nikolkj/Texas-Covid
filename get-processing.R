rm(list = ls());
require(tidyverse)
# require(magrittr)
# readxl

# Summarise Downloads for file-pickup ----
dir_downloads = "DataRepo/RawDownloads/"

files_downloads = lapply(X = paste0(dir_downloads, dir(dir_downloads)),
                         FUN = file.info) %>% 
  do.call(what = bind_rows, args = .) %>%
  mutate(FileName = dir(dir_downloads), 
         FilePath = rownames(.)) %>% 
  as_tibble()
  
# Processing (DailyCountyCaseCountData) ----
# Find most-recent download file
dat_target = files_downloads %>% 
  filter(str_detect(FileName, "DailyCountyCaseCountData")) %>% 
  filter(ctime == max(ctime)) %>% 
  select(FilePath) %>% unlist()

# Read Data file
dat = readxl::read_xlsx(path = dat_target, range = "A3:ZZ1000",sheet =  1, col_names = TRUE)

# Remove non-data observations
dat = slice_head(.data = dat, n = (which(dat$`County Name` == "Total")[1]) - 1) # drop non-data rows
dat = dat[, c(1:min(grep("^\\.+\\d+", names(dat)))-1)]  %>% # drop non-data columns
  select(-Population)

# Wide-to-long 
dat = dat %>% 
  pivot_longer(data = ., cols = -`County Name`, names_to = "Date", values_to = "DailyCount") %>% 
  mutate(Date = paste0(str_extract(string = Date, "\\d+-\\d+$"), "-2019"),
         Date = as.Date(Date, format = "%m-%d-%y")) %>% 
  rename(County = `County Name`)

# Calculate daily-deltas
dat = dat %>% 
  arrange(County, Date) %>% 
  group_by(County) %>% 
  mutate(DailyCountLag = dplyr::lag(DailyCount),
         DailyDelta = DailyCount - DailyCountLag) %>% 
  ungroup() %>% 
  select(-DailyCountLag)

# Create output copy of daily case counts
dat_cases = dat 

rm(dat)

# Processing (CountyFatalityCountData) ----
# Find most-recent download file
dat_target = files_downloads %>% 
  filter(str_detect(FileName, "DailyCountyFatalityCountData")) %>% 
  filter(ctime == max(ctime)) %>% 
  select(FilePath) %>% unlist()

# Read Data file
dat = readxl::read_xlsx(path = dat_target, range = "A3:ZZ1000",sheet =  1, col_names = TRUE)

# Remove non-data observations
dat = slice_head(.data = dat, n = (which(dat$`County Name` == "Total")[1]) - 1) # drop non-data rows
dat = dat[, c(1:min(grep("^\\.+\\d+", names(dat)))-1)]  %>% # drop non-data columns
  select(-Population)

# Wide-to-long 
dat = dat %>% 
  pivot_longer(data = ., cols = -`County Name`, names_to = "Date", values_to = "DailyCount") %>% 
  mutate(Date = paste0(str_extract(string = Date, "\\d+/\\d+$"), "/2019"),
         Date = as.Date(Date, format = "%m/%d/%y")) %>% 
  rename(County = `County Name`)

dat = dat %>% 
  arrange(County, Date) %>% 
  group_by(County) %>% 
  mutate(DailyCountLag = dplyr::lag(DailyCount),
         DailyDelta = DailyCount - DailyCountLag) %>% 
  ungroup() %>% 
  select(-DailyCountLag)

# Create output copy of daily fatality counts
dat_fatality = dat 

rm(dat)

# Processing (CummulativeCountyTestVolume) ----
# Find most-recent download file
dat_target = files_downloads %>% 
  filter(str_detect(FileName, "CummulativeCountyTestVolume")) %>% 
  filter(ctime == max(ctime)) %>% 
  select(FilePath) %>% unlist()

# Read Data file
dat = readxl::read_xlsx(path = dat_target, range = "A2:ZZ1000",sheet =  1, col_names = TRUE)

# Remove non-data observations
dat = slice_head(.data = dat, n = (which(dat$County == "TOTAL")[1]) - 1) # drop non-data rows
dat = dat[, c(1: (min(grep(pattern = "\\.\\.\\.", x = names(dat))) - 1)) ] # drop non-data columns

# Clean-up Column Names
names(dat)[-1] = gsub("[^[:digit:]]$", "", names(dat)[-1]) 

# Wide-to-long 
dat.class = setdiff(which(sapply(dat, class) != "numeric"), 1) # exception-handling, find non-numeric columns
  dat = dat[,-dat.class] # drop non-numeric columns

dat = dat %>% 
  pivot_longer(data = ., cols = -County, names_to = "Date", values_to = "DailyCount") %>% 
  mutate(Date = str_squish(str_replace(Date, "Tests Through", "")), 
         Date = paste0(Date, " 2019"),
         Date = as.Date(Date, format = "%B %d %y"))

dat = dat %>% 
  arrange(County, Date) %>% 
  group_by(County) %>% 
  mutate(DailyCountLag = dplyr::lag(DailyCount),
         DailyDelta = DailyCount - DailyCountLag) %>% 
  ungroup() %>% 
  select(-DailyCountLag)

# Create output copy of daily fatality counts
dat_tests = dat 

rm(dat)

# Finishing Touches ----
dat_cases$LastUpdateDate = Sys.Date()
dat_fatality$LastUpdateDate = Sys.Date()
dat_tests$LastUpdateDate = Sys.Date()

# Data Quality Checks -----
# ... tbd, compare against last successful export

# Write to File for GitHub Sync ----
# Write daily-copies to file
write_csv(x = dat_cases, 
          path = "daily-county-data/Texas-County-Cases.csv", na = "", col_names = TRUE)

write_csv(x = dat_fatality,
          path = "daily-county-data/Texas-County-Deaths.csv", na = "", col_names = TRUE)

write_csv(x = dat_tests,
          path = "daily-county-data/Texas-County-Tests.csv", na = "", col_names = TRUE)

# Commit and push daily-copies 

# Write Data to Database ----
# ... tbd












