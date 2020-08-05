#!/usr/bin/Rscript

# NOTE: Make sure that personal library mapped to R_LIBS_SITE variable in "/usr/lib/R/etc/Renviron" config file
# ... this case, /home/niko/R/x86_64-pc-linux-gnu-library/3.6
# ... see https://knausb.github.io/2017/07/r-3.4.1-personal-library-location/ for more details
# ... otherwise cron will fail to load non-otb packages 

rm(list = ls());
setwd("/home/niko/Documents/R-projects/TexasCovid") # must be explicityly set for cron task execution

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
dat = dat[, c(1:min(grep("^\\.+\\d+", names(dat)))-1)] # drop non-data columns
names(dat) = names(dat) %>% gsub("\\r", " ", .) %>% gsub("\\n"," ",x = .) %>% str_squish()


# Wide-to-long 
dat =  dat %>% 
  pivot_longer(data = ., cols = -`County Name`, names_to = "Date", values_to = "DailyCount") %>% 
  mutate(Date = paste0(str_extract(string = Date, "\\d{2,2}-\\d{2,2}"), "-2020"),
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
dat = readxl::read_xlsx(path = dat_target, range = "A3:ZZ1000",sheet =  1, col_names = TRUE, 
                        col_types = "text" # import as text, compensate for date-header import format issues 
                        )

# Remove non-data observations
dat = slice_head(.data = dat, n = (which(dat$`County Name` == "Grand Total" | dat$`County Name` == "Total")[1]) - 1) # drop non-data rows
dat = dat[, c(1:min(grep("^\\.+\\d+", names(dat)))-1)]  # drop non-data columns


# Wide-to-long 
dat =  dat %>% 
  pivot_longer(data = ., cols = -`County Name`, names_to = "Date", values_to = "DailyCount") %>%
  mutate(date_import_style = str_detect(Date, "/")) %>% # bifurcate data by different [Date] formats
  group_by(date_import_style) %>% nest()

# Fix Date-values
if(TRUE %in% dat$date_import_style){
dat$data[[which(dat$date_import_style)]] = dat$data[[which(dat$date_import_style)]] %>% 
  mutate(Date = as.Date(Date, format = "%m/%d/%Y"))
}

if(FALSE %in% dat$date_import_style){
dat$data[[which(!dat$date_import_style)]] = dat$data[[which(!dat$date_import_style)]] %>% 
  mutate(Date = as.numeric(Date) - 2, # manual adjustment of (-2) based on observed data. Not sure why things don't align with standard origin 
         Date = as.Date(Date, origin = "1900-01-01")) 
}

dat = dat %>% 
  unnest(cols = c("data")) %>% ungroup() %>%  
  rename(County = `County Name`) %>%
  arrange(County, Date) %>% 
  select(-date_import_style) %>% 
  mutate(DailyCount = as.numeric(DailyCount))

# Aggregegate, calcululate [DailyDelta]
dat = dat %>% 
  arrange(County, Date) %>% 
  group_by(County) %>% 
  mutate(DailyCountLag = dplyr::lag(DailyCount),
         DailyDelta = DailyCount - DailyCountLag) %>% 
  ungroup() %>% 
  select(-DailyCountLag) %>%
  mutate(County = stringr::str_to_title(County)) %>% # match to all other data-files
  filter(toupper(County) != "UNKNOWN")

# Manual [County] fixes to match other files
dat$County[which(dat$County == "De Witt")] = "DeWitt"
dat$County[which(dat$County == "Mcculloch")] = "McCulloch"
dat$County[which(dat$County == "Mclennan")] = "McLennan"



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
         Date = paste0(Date, " 2020"),
         Date = as.Date(Date, format = "%B %d %y"))

dat = dat %>% 
  arrange(County, Date) %>% 
  group_by(County) %>% 
  mutate(DailyCountLag = dplyr::lag(DailyCount),
         DailyDelta = DailyCount - DailyCountLag) %>% 
  ungroup() %>% 
  select(-DailyCountLag)

# Create output copy of daily tests counts
dat_tests = dat 
rm(dat)

# Processing (DailyTSAHospitalCapacity) ----
dat_target = files_downloads %>% 
  filter(str_detect(FileName, "DailyTSAHospitalCapacity")) %>% 
  filter(ctime == max(ctime)) %>% 
  select(FilePath) %>% unlist()

# Read Data file
dat = readxl::read_xlsx(path = dat_target, range = "A3:ZZ1000",sheet =  1, col_names = TRUE)

# Remove non-data observations
dat = slice_head(.data = dat, n = (which(dat$`TSA ID` == "Total")[1]) - 1) # drop non-data rows
dat = dat[, c(1:min(grep("^\\.+\\d+", names(dat)))-1)] # drop non-data columns

# Convert to <numeric>
dat[,c(3:ncol(dat))] = dat[,c(3:ncol(dat))] %>% sapply(X = ., as.numeric)

# Wide-to-long 
dat = dat %>% 
  pivot_longer(data = ., cols =  -c(`TSA ID`, `TSA AREA`), names_to = "Date", values_to = "DailyCount") %>% 
  mutate(Date = as.Date(Date)) %>%
  rename(TSA_ID = `TSA ID`, TSA_Name = `TSA AREA`) %>% 
  mutate(TSA_ID = str_remove(string = TSA_ID, "[^[A-z]]") %>% str_trim())

dat = dat %>% 
  arrange(TSA_ID, Date) %>% 
  group_by(TSA_ID) %>% 
  mutate(DailyCountLag = dplyr::lag(DailyCount),
         DailyDelta = DailyCount - DailyCountLag) %>% 
  ungroup() %>% 
  select(-DailyCountLag)

# Create output copy of daily tests counts
dat_capacity = dat 
rm(dat)


# Processing (DailyTSAHospitalizations) ----
dat_target = files_downloads %>% 
  filter(str_detect(FileName, "DailyTSAHospitalizations")) %>% 
  filter(ctime == max(ctime)) %>% 
  select(FilePath) %>% unlist()

# Read Data file
dat = readxl::read_xlsx(path = dat_target, range = "A3:ZZ1000",sheet =  1, col_names = TRUE)

# Remove non-data observations
dat = slice_head(.data = dat, n = (which(dat$`TSA ID` == "Total")[1]) - 1) # drop non-data rows
dat = dat[, c(1:min(grep("^\\.+\\d+", names(dat)))-1)] # drop non-data columns

# Convert to <numeric>
dat[,c(3:ncol(dat))] = dat[,c(3:ncol(dat))] %>% sapply(X = ., as.numeric)

# Wide-to-long 
dat = dat %>% 
  pivot_longer(data = ., cols =  -c(`TSA ID`, `TSA AREA`), names_to = "Date", values_to = "DailyCount") %>% 
  mutate(Date = as.Date(Date)) %>%
  rename(TSA_ID = `TSA ID`, TSA_Name = `TSA AREA`) %>% 
  mutate(TSA_ID = str_remove(string = TSA_ID, "[^[A-z]]") %>% str_trim())

dat = dat %>% 
  arrange(TSA_ID, Date) %>% 
  group_by(TSA_ID) %>% 
  mutate(DailyCountLag = dplyr::lag(DailyCount),
         DailyDelta = DailyCount - DailyCountLag) %>% 
  ungroup() %>% 
  select(-DailyCountLag)

# Create output copy of daily tests counts
dat_hospitalization = dat 
rm(dat)

# Combine datat-sets into "dat_main" ----
# Joins 
# ... joins all dat_* items, needs to be updated if additional DSHS data-sources added
dat_main = dat_cases %>% 
  rename(DailyCount_cases = DailyCount, DailyDelta_cases = DailyDelta) %>%
  left_join(x = ., 
            y = (dat_tests %>%
                   rename(DailyCount_tests = DailyCount,
                          DailyDelta_tests = DailyDelta)), 
            by = c("County", "Date")) %>%
  left_join(x = ., 
            y = (dat_fatality %>%
                   rename(DailyCount_deaths = DailyCount,
                          DailyDelta_deaths = DailyDelta)), 
            by = c("County", "Date"))

dat_TSA = dat_hospitalization %>%
  rename(DailyCount_patients  = DailyCount,
         DailyDelta_patients  = DailyDelta) %>% 
    left_join(x = .,
            y = (dat_capacity %>% select(-TSA_Name) %>%
                   rename(DailyCount_beds  = DailyCount,
                          DailyDelta_beds  = DailyDelta)),
            by = c("TSA_ID", "Date"))
  
# Normalize County Names
# ... Only applied to "dat_main" & "dat_TSA" since it's used with other personal projects
# ... and needs to conform to uniform standards.
# ... 
# ... All other dat_* objects retain source formatting. 
dat_main = dat_main %>%
  mutate(County = stringr::str_to_title(County, locale = "en")) 

dat_TSA = dat_TSA %>% 
  mutate(TSA_Name = stringr::str_to_title(TSA_Name, locale = "en"))

# Finishing Touches ----
dat_cases$LastUpdateDate = Sys.Date()
dat_fatality$LastUpdateDate = Sys.Date()
dat_tests$LastUpdateDate = Sys.Date()
dat_main$LastUpdateDate = Sys.Date()

dat_capacity$LastUpdateDate = Sys.Date()
dat_hospitalization$LastUpdateDate = Sys.Date()
dat_TSA$LastUpdateDate = Sys.Date()

# Data Quality Checks -----
# ... tbd, compare against last successful export

# Write to File for GitHub Sync ----

# Write daily-copies to file
# ... Just write to local here
# ... Commit and push of daily-copies handled by git in primary shell script

# Write Files to project directories
write_csv(x = dat_cases, 
          path = "/home/niko/Documents/R-projects/TexasCovid/daily-county-data/Texas-County-Cases.csv", na = "", col_names = TRUE)

write_csv(x = dat_fatality,
          path = "/home/niko/Documents/R-projects/TexasCovid/daily-county-data/Texas-County-Deaths.csv", na = "", col_names = TRUE)

write_csv(x = dat_tests,
          path = "/home/niko/Documents/R-projects/TexasCovid/daily-county-data/Texas-County-Tests.csv", na = "", col_names = TRUE)

write_csv(x = dat_main,
          path = "/home/niko/Documents/R-projects/TexasCovid/daily-county-data/Texas-County-Main.csv", na = "", col_names = TRUE)

write_csv(x = dat_hospitalization,
          path = "/home/niko/Documents/R-projects/TexasCovid/daily-county-data/Texas-County-Hospitalizations.csv", na = "", col_names = TRUE)

write_csv(x = dat_capacity,
          path = "/home/niko/Documents/R-projects/TexasCovid/daily-county-data/Texas-County-HospitalCapacity.csv", na = "", col_names = TRUE)

write_csv(x = dat_TSA,
          path = "/home/niko/Documents/R-projects/TexasCovid/daily-county-data/Texas-County-TSA.csv", na = "", col_names = TRUE)


# Write Files to related project directories
write_csv(x = dat_main,
          path = "/home/niko/Documents/R-projects/TexasCovid-modeling/shiny-server_files/Texas-County-Main.csv", na = "", col_names = TRUE)

write_csv(x = dat_TSA,
          path = "/home/niko/Documents/R-projects/TexasCovid-modeling/shiny-server_files/Texas-County-TSA.csv", na = "", col_names = TRUE)

# Write Data to Database ----
# ... tbd












