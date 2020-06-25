
## Summary 
Daily publication of cleaned and tidy Texas county-level Covid-19 statistics, as published by Texas DSHS.\
Original data sourced from <https://www.dshs.state.tx.us/coronavirus/additionaldata/>; ugly excel, beware. 

Tidy data can be accessed here:

* Daily Cases: <https://raw.githubusercontent.com/nikolkj/Texas-Covid/master/daily-county-data/Texas-County-Cases.csv>
* Daily Fatalities: <https://raw.githubusercontent.com/nikolkj/Texas-Covid/master/daily-county-data/Texas-County-Deaths.csv>
* Daily Tests: <https://raw.githubusercontent.com/nikolkj/Texas-Covid/master/daily-county-data/Texas-County-Tests.csv>
* Combined Daily File: <https://raw.githubusercontent.com/nikolkj/Texas-Covid/master/daily-county-data/Texas-County-Main.csv>

Data has been cleaned at put in a *long* format for easy visualization and modeling.

All data-tables have the following fields:

1. "County": Texas county name <factor>
2. "Date": Date associated with observation, YYYY-MM-DD format. 
3. "DailyCount": Aggregate measure, to-date, as published by DSHS.
4. "DailyDelta": Calculated daily measure ($x_{t} - x_{t-1}$) to get e.g. new cases for a given day
5. "LastUpdateDate": Date when the data was pulled.

DSHS updates data everyday around ~9:30am CST, tidy-data is then updated at 10:30am CST. 
&nbsp;

## Getting Data

Read data from github link.

```r
dat = read_csv(file = "https://raw.githubusercontent.com/nikolkj/Texas-Covid/master/daily-county-data/Texas-County-Cases.csv", col_names = TRUE, progress = FALSE)
```

```
## Parsed with column specification:
## cols(
##   County = col_character(),
##   Date = col_date(format = ""),
##   DailyCount = col_double(),
##   DailyDelta = col_double(),
##   LastUpdateDate = col_date(format = "")
## )
```

Examine some data sample.

```r
dat %>% 
  filter(Date > "2020-04-15", DailyCount > 100) %>%
  sample_n(15) %>% 
  kable() %>% kableExtra::kable_styling(kable_input = ., bootstrap_options = c("striped", "hover"))
```

<table class="table table-striped table-hover" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> County </th>
   <th style="text-align:left;"> Date </th>
   <th style="text-align:right;"> DailyCount </th>
   <th style="text-align:right;"> DailyDelta </th>
   <th style="text-align:left;"> LastUpdateDate </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Collin </td>
   <td style="text-align:left;"> 2020-05-21 </td>
   <td style="text-align:right;"> 1090 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Kaufman </td>
   <td style="text-align:left;"> 2020-05-10 </td>
   <td style="text-align:right;"> 116 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Grayson </td>
   <td style="text-align:left;"> 2020-06-03 </td>
   <td style="text-align:right;"> 350 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hidalgo </td>
   <td style="text-align:left;"> 2020-05-07 </td>
   <td style="text-align:right;"> 359 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Montgomery </td>
   <td style="text-align:left;"> 2020-06-07 </td>
   <td style="text-align:right;"> 1064 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hardin </td>
   <td style="text-align:left;"> 2020-05-23 </td>
   <td style="text-align:right;"> 136 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Potter </td>
   <td style="text-align:left;"> 2020-05-21 </td>
   <td style="text-align:right;"> 2196 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bowie </td>
   <td style="text-align:left;"> 2020-06-05 </td>
   <td style="text-align:right;"> 301 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Randall </td>
   <td style="text-align:left;"> 2020-05-17 </td>
   <td style="text-align:right;"> 602 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bell </td>
   <td style="text-align:left;"> 2020-05-15 </td>
   <td style="text-align:right;"> 242 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Taylor </td>
   <td style="text-align:left;"> 2020-05-02 </td>
   <td style="text-align:right;"> 327 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Harris </td>
   <td style="text-align:left;"> 2020-06-02 </td>
   <td style="text-align:right;"> 12664 </td>
   <td style="text-align:right;"> 388 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hays </td>
   <td style="text-align:left;"> 2020-06-07 </td>
   <td style="text-align:right;"> 385 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hardin </td>
   <td style="text-align:left;"> 2020-05-30 </td>
   <td style="text-align:right;"> 138 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Coryell </td>
   <td style="text-align:left;"> 2020-05-15 </td>
   <td style="text-align:right;"> 221 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 2020-06-10 </td>
  </tr>
</tbody>
</table>

## Reporting Data

Find when new cases peaked for each county, take top 10.

```r
dat %>% group_by(County) %>%
  filter(DailyDelta == max(DailyDelta, na.rm = T)) %>%
  rename(PeakDate = Date, PeakCases = DailyDelta) %>%
  arrange(desc(PeakCases)) %>% head(n = 10) %>% 
  select(County, PeakDate, PeakCases) %>%
  kable() %>% kableExtra::kable_styling(kable_input = ., bootstrap_options = c("striped", "hover"), full_width = FALSE, position = "left")
```

<table class="table table-striped table-hover" style="width: auto !important; ">
 <thead>
  <tr>
   <th style="text-align:left;"> County </th>
   <th style="text-align:left;"> PeakDate </th>
   <th style="text-align:right;"> PeakCases </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Harris </td>
   <td style="text-align:left;"> 2020-04-10 </td>
   <td style="text-align:right;"> 706 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Potter </td>
   <td style="text-align:left;"> 2020-05-16 </td>
   <td style="text-align:right;"> 618 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Walker </td>
   <td style="text-align:left;"> 2020-05-31 </td>
   <td style="text-align:right;"> 510 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Tarrant </td>
   <td style="text-align:left;"> 2020-05-11 </td>
   <td style="text-align:right;"> 485 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Dallas </td>
   <td style="text-align:left;"> 2020-05-22 </td>
   <td style="text-align:right;"> 369 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Jones </td>
   <td style="text-align:left;"> 2020-05-28 </td>
   <td style="text-align:right;"> 222 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> El Paso </td>
   <td style="text-align:left;"> 2020-06-04 </td>
   <td style="text-align:right;"> 197 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bexar </td>
   <td style="text-align:left;"> 2020-05-31 </td>
   <td style="text-align:right;"> 189 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Moore </td>
   <td style="text-align:left;"> 2020-06-02 </td>
   <td style="text-align:right;"> 149 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Medina </td>
   <td style="text-align:left;"> 2020-06-06 </td>
   <td style="text-align:right;"> 138 </td>
  </tr>
</tbody>
</table>

## Plotting Data


```r
dat %>%
  filter(!is.na(DailyDelta), 
         County %in% c("Harris","Dallas","Bexar","Walker")) %>%
  mutate(County = factor(County)) %>%
  select(County, Date, DailyDelta) %>% 
  ggplot(data = ., mapping = aes(x = Date, y = DailyDelta, col = County)) +
  geom_line() + 
  ggtitle("New Cases", subtitle = "For select counties") +
  ylab("") + xlab("") +
  scale_x_date(labels = scales::date_format(format = "%m/%d")) + 
  ggthemes::theme_fivethirtyeight()
```

![](README_files/figure-html/unnamed-chunk-4-1.png)<!-- -->



```r
dat %>% 
  filter(County %in% c("Harris","Dallas","Bexar","Walker"),
         DailyCount > 0,
         Date > "2020-03-15") %>%
  mutate(County = factor(County)) %>%
  select(County, Date, DailyCount) %>% 
  ggplot(data = ., mapping = aes(x = Date, y = DailyCount, col = County)) +
  geom_line() + 
  ggtitle("Total Cases", subtitle = "For select counties") +
  ylab("") + xlab("") +
  scale_y_continuous(na.value = 0, trans = "log10", labels = scales::number_format(big.mark = ",", accuracy = 1)) +
  scale_x_date(labels = scales::date_format(format = "%m/%d")) + 
  ggthemes::theme_fivethirtyeight()
```

<img src="README_files/figure-html/unnamed-chunk-5-1.png" style="display: block; margin: auto auto auto 0;" />


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

