
# -----------------------------------------------------------------------------------------------  

##                     WIMLDS Data Dive 
##                  D4 - Data Visualization team 
##                     Smart Cities Hack 

# -----------------------------------------------------------------------------------------------  



# -----------------------------------------------------------------------------------------------  

##                     setup 

# -----------------------------------------------------------------------------------------------  

# install.packages('devtools')
devtools::install_github("rstats-db/bigrquery")

library(bigrquery)
library(dplyr)
library(raster)
library(janitor) 
library(viridis)


projectid <- "spheric-crow-161317" 

query <- "SELECT
TIMESTAMP_TRUNC(pickup_datetime,
MONTH) months,
COUNT(*) trips
FROM
`bigquery-public-data.new_york.tlc_yellow_trips_2015`
GROUP BY
1
ORDER BY
1"
test = query_exec(query, projectid, useLegacySql = FALSE)
# routes you to log in with the gmail account you used to sign up for the hackathon 
 

# -----------------------------------------------------------------------------------------------  

#           convenience function

# -----------------------------------------------------------------------------------------------  

# shortcut for query_exec 
q = function(x){
    query_exec(x, project = projectid, useLegacySql = FALSE)
}

# -----------------------------------------------------------------------------------------------  

##                      traffic data  

# -----------------------------------------------------------------------------------------------  

# get traffic data for ones that start near grand central/penn and stop in wall street 
traf = "select pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude from `bigquery-public-data.new_york.tlc_yellow_trips_2016` where (
(pickup_latitude between (40.7508860 - 0.002) and (40.7508860 + 0.002)) and
(pickup_longitude between (-73.9839130 - 0.01) and (-73.9839130 + 0.01)) and
(dropoff_latitude between (40.7048660 - 0.0021) and (40.7048660 + 0.0021)) and
(dropoff_longitude between (-74.0127830 - 0.002) and (-74.0127830 + 0.002)))"
trafdf = query_exec(traf, projectid, useLegacySql = FALSE)

# write to csv   
dir.create('data')
write.csv(trafdf, "data/traffic_latlong_from_sql.csv")

# -----------------------------------------------------------------------------------------------  

##                      complaint data - traffic congestion 

# -----------------------------------------------------------------------------------------------  

# get col names and class types 
colnames = "SELECT * 
    FROM `bigquery-public-data.new_york.311_service_requests`
LIMIT 1"
colnames311 = q(colnames) 

# download all traffic complaint data from `bigquery-public-data.new_york.311_service_requests`
compsnypd = "SELECT unique_key, created_date, closed_date, agency, complaint_type, descriptor,
borough, incident_zip, latitude, longitude, location 
FROM 
`bigquery-public-data.new_york.311_service_requests`
WHERE 
(complaint_type = 'Traffic') and 
(created_date between ('2016-01-01 00:00:00') and ('2016-12-31 23:59:59')) and 
(descriptor = 'Congestion/Gridlock') and 
(borough = 'MANHATTAN')
"
comps = q(compsnypd) 

# zip codes of interest 
zips = c(10001, 10011, 10018, 10019, 10020, 10036,	10010, 10016, 10017, 10022, 10012, 10013, 10014, 10004, 10005, 10006, 10007, 10038, 10280, 	10002, 10003, 10009)


# create other date / time variables 
comps = comps %>% 
    mutate(starttime = strftime(.$created_date, format="%H:%M:%S")) %>% 
    mutate(hour = strftime(.$created_date, format="%H")) %>% 
    mutate(month = strftime(.$created_date, format="%B")) %>% 
    mutate(weekday = weekdays(as.Date(.$created_date))) %>% 
    filter(incident_zip %in% zips)

# get months and dates in the right order 
monlevels=c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
daylevels=c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
comps$weekday <- factor(comps$weekday, levels=daylevels)
comps$month <- factor(comps$month, levels=monlevels)

# filter out just the weekdays
weekday_comps = comps %>% 
    filter(weekday != "Saturday" & weekday!= "Sunday")
# not necessary 
# weekday_comps$weekday = droplevels(weekday_comps$weekday)
# weekday_comps$weekday = factor(weekday_comps$weekday, levels = weekdaylevels)  

# write to csv 
write.csv(comps, "data/congestion_complaints.csv")
write.csv(weekday_comps, "data/complaints_lower_manhattan.csv")

# -----------------------------------------------------------------------------------------------  

##                      steady plottin'

# -----------------------------------------------------------------------------------------------  

f = ggplot(weekday_comps, aes(x=weekday, fill = weekday)) +
    (stat="count") + 
    scale_fill_viridis(discrete = T) +
    theme(plot.title = element_text(size=rel(2.5))) + 
    ggtitle("Traffic congestion complaints by day of the week") +
    theme_bw()
f # <- ( lol )  

# by month 
m = ggplot(weekday_comps, aes(x=weekday, fill = weekday)) 
m + geom_bar(stat="count") + 
    ggtitle("Traffic congestion complaints by day of the week") + scale_fill_viridis(discrete = T)
 
# save to png 
if (!dir.exists("figs")) dir.create("figs")
png("Friday Rage.png", width = 700, height = 480)
f
dev.off() 
 
# plotting by hour and by month 
p <- ggplot(comps, aes(x=hour, fill = month)) + 
    geom_histogram(stat = "count") + 
    scale_fill_viridis(discrete = TRUE) + 
    ggtitle("Traffic Congestion complaints by hour and month")
p 


# -----------------------------------------------------------------------------------------------  

##                      air quality complaints 

# -----------------------------------------------------------------------------------------------  
# download air quality complaints data from 311 
compsair = "SELECT unique_key, created_date, closed_date, agency, complaint_type, descriptor,
borough, incident_zip, latitude, longitude, location  FROM 
`bigquery-public-data.new_york.311_service_requests`
WHERE 
complaint_type = 'Air Quality' and 
(created_date between ('2016-01-01 00:00:00') and ('2016-12-31 23:59:59')) and  
(borough = 'MANHATTAN')"
air = q(compsair)
airdf = air  # make a backup 

# filter to only vehicular air complaints 
air = airdf %>% 
    filter(descriptor == "Air: Odor/Fumes, Vehicle Idling (AD3)" | 
               descriptor ==  "Air: Smoke, Vehicular (AA4)" ) %>% 
    mutate(starttime = strftime(.$created_date, format="%H:%M:%S")) %>% 
    mutate(hour = strftime(.$created_date, format="%H")) %>% 
    mutate(month = strftime(.$created_date, format="%B")) %>% 
    mutate(weekday = weekdays(as.Date(.$created_date))) %>% 
    filter(incident_zip %in% zips) %>% 
    filter(weekday != "Saturday" & weekday != "Sunday") 

# fix levels 
monlevels=c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
daylevels=c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
air$weekday <- factor(air$weekday, levels=daylevels)
air$month <- factor(air$month, levels=monlevels)
 

# by month
m = ggplot(air, aes(x=month, fill = hour)) +
    geom_bar(stat="count") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
    ggtitle("Air quality complaints by month") + 
    scale_fill_viridis(discrete = T)  

# save 
png('figs/air_quality_by_month.png', width = 700, height = 480)
m 
dev.off()

# save data to csv  
write.csv(air, "data/air_complaints_lower_m.csv")