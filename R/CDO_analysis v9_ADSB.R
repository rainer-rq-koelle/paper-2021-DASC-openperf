
# CDO Analysis of FR24 data

library("ROracle")
library("dplyr")
library("zoo")
library("reshape2")
library("ggplot2")
library("scales")
library("openxlsx")

Sys.setenv(TZ = "UTC")
Sys.setenv(ORA_SDTZ = "UTC")
# dir_PRU="G:/HQ/dgof-pru/Project/Vertical_flight_efficiency/2015/CDO_CCO/"

Radius=200 #NM
VV_threshold=3/60 #FL/second
# Time_threshold=6 #seconds
# Alt_threshold=2 #FL
Min_time=20 #seconds
Tol=0.90 #Percentage of the maximum altitude
Min_time_tol=5*60 #seconds
Alt_min=18 #FL
# start_date=format(as.POSIXct("2020-02-13"), "%d-%b-%Y")
# end_date=format(as.POSIXct("2020-04-15"), "%d-%b-%Y")
Min_points=5

Gap_max_duration=120 #seconds
VV_glitch_limit=10000/60 #feet/second
Dist_glitch_limit=50 #NM
Minpoints=10

Timegap=1 #0=Active,1=Not active
Vertical_glitch=0
Horizontal_glitch=1
Sequence_error=0
AnyError=1

drv <- dbDriver("Oracle")
con <- dbConnect(drv, "PRUTEST", "test", dbname='SAMAD20')
APT_data <- dbGetQuery(con, "SELECT * FROM SP_AIRPORT_INFO")
dbDisconnect(con)

SP_dist_NM <- function(lon1, lat1, lon2, lat2){
  a=6378.137/1.852 #NM
  b=6356.7523/1.852 #NM
  deg2rad=pi/180
  LAT_avg=(lat1+lat2)/2*deg2rad;
  R=sqrt(((a^2*cos(LAT_avg))^2+(b^2*sin(LAT_avg))^2)/((a*cos(LAT_avg))^2+(b*sin(LAT_avg))^2));
  Delta_LON=(lon2-lon1)*deg2rad;
  Delta_LAT=(lat2-lat1)*deg2rad;
  Distance=2*R*asin(sqrt((sin(Delta_LAT/2))^2+cos(lat1*deg2rad)*cos(lat2*deg2rad)*(sin(Delta_LON/2))^2));
  
  return(Distance)
}

source("R/Outlier_filter.R")

data_temp=arrange(data_temp, firstseen, callsign, timestamp) %>% 
  mutate(date_firstseen=format(firstseen, "%d%m%Y"),
         flight_id=paste(icao24, callsign,date_firstseen, sep="-", collapse = NULL), 
         TIME_OVER=timestamp) %>% 
  arrange(flight_id, TIME_OVER) %>%
  Alt_Outlier_filter(KernelSize=17, Fill=TRUE, IntResults=FALSE) %>% 
  Alt_Outlier_filter(KernelSize=53, Fill=TRUE, IntResults=FALSE) %>% 
  mutate(altitude=altitude/100) %>% 
  left_join(select(APT_data, ICAO_CODE, ARP_LAT, ARP_LON, ELEVATION_FEET), by=c("destination"="ICAO_CODE")) %>% 
  mutate(GCD_ARP=SP_dist_NM(ARP_LON, ARP_LAT, longitude, latitude),
         APT_elev=ELEVATION_FEET/100) %>% 
  filter(GCD_ARP<=Radius) %>% 
  group_by(flight_id) %>% 
  mutate(SEQ_ID=row_number()) %>% 
  select(-ELEVATION_FEET)


lvl_seg_temp=data.frame(flight_id=numeric(), LON_START=numeric(), LAT_START=numeric(), ALT_START=numeric(), TIME_START=as.POSIXct(character()),
                        LON_END=numeric(), LAT_END=numeric(), ALT_END=numeric(), TIME_END=as.POSIXct(character()),
                        TIME_LEVEL_SECONDS=numeric(), CONSIDERED=numeric(), EXCL_BOX=numeric(), TOO_LOW=numeric(), TOO_SHORT=numeric())
Flight_data_temp=data.frame(flight_id=numeric(), TOD_LON=numeric(), TOD_LAT=numeric(), TOD_FLIGHT_LEVEL=numeric(),
                            TOD_TIME_OVER=as.POSIXct(character()), END_LON=numeric(), END_LAT=numeric(), END_FLIGHT_LEVEL=numeric(),
                            END_TIME_OVER=as.POSIXct(character()), ALT_MAX=numeric(), DESCENT_TIME_SECONDS=numeric(), schd_from=character(), schd_to=character(),
                            real_to=character(), equip=character(), callsign=character(), reg=character())


# Verify that only descent part is taken into account (look for last point at highest altitude)
last_seq_id=data_temp %>%
  group_by(flight_id) %>%
  filter(round(altitude)==max(round(altitude))) %>%
  mutate(last_seqid=max(SEQ_ID)) %>%
  as.data.frame() %>%
  select(flight_id,last_seqid) %>%
  unique()

data_temp=data_temp %>%
  left_join(last_seq_id) %>%
  filter(SEQ_ID>=last_seqid) %>%
  select(-matches("last_seqid"))

# Check the number of data points for each flight
Nbr_data_points=data_temp %>%
  group_by(flight_id) %>%
  summarise(Count=n()) %>%
  filter(Count>=Min_points)

# Remove flights with too few data points
data_extended=Nbr_data_points %>%
  left_join(data_temp) %>%
  select(-Count)

data_extended=arrange(data_extended, flight_id, TIME_OVER) %>% 
  # mutate(flight_id=as.integer(flight_id)) %>%
  group_by(flight_id)

data_int=data_extended %>%
  mutate(LEVEL=ifelse(abs((altitude-lead(altitude))/as.numeric(difftime(TIME_OVER, lead(TIME_OVER), units="secs")))<=VV_threshold, 1, 0),
         BEGIN=ifelse(LEVEL==1 & (lag(LEVEL)==0 | TIME_OVER==min(TIME_OVER)), 1, 0),
         END=ifelse((((LEVEL==0 & TIME_OVER!=min(TIME_OVER) & lag(LEVEL)) | (is.na(LEVEL) & lag(LEVEL)))==1), 1, 0)) %>%
  as.data.frame()

Flight_data=summarise(group_by(data_int, flight_id), ALT_MAX=max(round(altitude/10)*10))

Begins=data_int %>%
  filter(BEGIN==1) %>%
  left_join(Flight_data, by="flight_id") %>%
  select(flight_id, LON_START=longitude, LAT_START=latitude, ALT_START=altitude, TIME_START=TIME_OVER)
Ends=data_int %>%
  ungroup() %>%
  filter(END==1) %>%
  select(LON_END=longitude, LAT_END=latitude, ALT_END=altitude, TIME_END=TIME_OVER)
lvl_seg=cbind(Begins, Ends)

lvl_seg=lvl_seg %>% 
  left_join(Flight_data) %>%
  left_join(unique(select(data_temp, flight_id, APT_elev))) %>%
  mutate(TIME_LEVEL_SECONDS=as.numeric(difftime(TIME_END, TIME_START, units="secs")),
         CONSIDERED=ifelse((TIME_LEVEL_SECONDS>=Min_time & (ALT_START+ALT_END)/2>=(Alt_min+APT_elev)), 
                           ifelse(round((ALT_START+ALT_END)/2/10)*10>=ALT_MAX,
                                  0,
                                  ifelse(!((ALT_START+ALT_END)/2>=Tol*ALT_MAX &
                                             abs(as.numeric(difftime(TIME_START, TIME_END, units="secs")))>Min_time_tol),1,0)),
                           0),
         EXCL_BOX=ifelse(round((ALT_START+ALT_END)/2/10)*10>=ALT_MAX,
                         1,
                         ifelse(!((ALT_START+ALT_END)/2>=Tol*ALT_MAX &
                                    abs(as.numeric(difftime(TIME_START, TIME_END, units="secs")))>Min_time_tol),0,1)),
         TOO_LOW=ifelse((ALT_START+ALT_END)/2>=(Alt_min+APT_elev), 0, 1),
         TOO_SHORT=ifelse(TIME_LEVEL_SECONDS>=Min_time, 0, 1)
  ) %>%
  select(-matches("ALT_MAX"), -APT_elev)


# Flight data extraction

TODA200=data_int %>%
  left_join(Flight_data, by="flight_id") %>%
  group_by(flight_id) %>%
  mutate(TOD_A200=ifelse(max(END==1 & round(altitude/10)*10==ALT_MAX)==1,
                         SEQ_ID[END==1 & round(altitude/10)*10==ALT_MAX],
                         SEQ_ID[round(altitude/10)*10==ALT_MAX])) %>%
  select(flight_id, TOD_A200) %>%
  unique() %>%
  as.data.frame()

Samids=select(data_int, flight_id) %>% unique()
if (nrow(lvl_seg)>0){
  TODCDO=data_int %>%
    left_join(lvl_seg, by="flight_id") %>%
    group_by(flight_id) %>%
    filter(TIME_OVER==TIME_END & EXCL_BOX==1) %>%
    mutate(TOD_CDO=max(SEQ_ID)) %>%
    select(flight_id, TOD_CDO) %>%
    unique() %>%
    as.data.frame()
} else {
  TODCDO=cbind(Samids, TOD_CDO=NA)
}

TOD=TODA200 %>%
  left_join(TODCDO) %>%
  group_by(flight_id) %>%
  mutate(TOD=ifelse(is.na(TOD_CDO),TOD_A200,TOD_CDO)) %>%
  select(TOD) %>%
  as.data.frame()

if (nrow(lvl_seg)>0){
  end_lvl_index=data_int %>%
    left_join(filter(lvl_seg, TOO_LOW==0), by="flight_id") %>%
    group_by(flight_id) %>%
    filter(TIME_OVER==TIME_END) %>%
    mutate(end_lvl_idx=max(SEQ_ID)) %>%
    select(end_lvl_idx) %>%
    unique() %>%
    as.data.frame()
} else {
  end_lvl_index=cbind(Samids, end_lvl_idx=NA)
}

end_index_temp=data_int %>%
  left_join(unique(select(data_temp, flight_id, APT_elev))) %>%
  group_by(flight_id) %>%
  filter(altitude>=(Alt_min+APT_elev)) %>%
  mutate(end_idx=max(SEQ_ID)) %>%
  select(end_idx) %>%
  unique() %>%
  as.data.frame()

end_index=end_index_temp %>%
  left_join(end_lvl_index) %>%
  group_by(flight_id) %>%
  mutate(end_idx2=max(end_lvl_idx,end_idx, na.rm=TRUE)) %>%
  select(end_idx2) %>%
  rename(end_idx=end_idx2) %>%
  as.data.frame()

Flight_data=Flight_data %>%
  left_join(TOD) %>%
  left_join(data_int, by="flight_id") %>%
  group_by(flight_id) %>%
  filter(SEQ_ID==TOD) %>%
  select(flight_id, TOD_LON=longitude, TOD_LAT=latitude, TOD_FLIGHT_LEVEL=altitude, TOD_TIME_OVER=TIME_OVER, ALT_MAX) %>%
  left_join(end_index) %>%
  left_join(data_int, by="flight_id") %>%
  filter(SEQ_ID==end_idx) %>%
  left_join(unique(select(data_temp, flight_id, destination))) %>% 
  select(flight_id, TOD_LON, TOD_LAT, TOD_FLIGHT_LEVEL, TOD_TIME_OVER, END_LON=longitude, END_LAT=latitude, END_FLIGHT_LEVEL=altitude,
         END_TIME_OVER=TIME_OVER, ALT_MAX, ADES=destination) %>%
  mutate(DESCENT_TIME_SECONDS=as.numeric(difftime(END_TIME_OVER, TOD_TIME_OVER, units="secs"))) %>%
  as.data.frame()

