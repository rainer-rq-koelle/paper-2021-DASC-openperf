

# lvl_seg_temp & Flight_data_temp to be replaced by names of saved files

Lvl_seg_all=lvl_seg %>%
  filter(CONSIDERED==1) %>%
  unique() %>%
  cbind(nbr=1) %>%
  mutate(ALT_START=ALT_START*100, ALT_END=ALT_END*100)

Flight_data_all=filter(Flight_data, DESCENT_TIME_SECONDS>0) %>% unique()


CDO_results_per_flight=Flight_data_all %>%
  left_join(Lvl_seg_all, by="flight_id") %>%
  group_by(flight_id) %>%
  summarise(TIME_LEVEL_SECONDS=sum(TIME_LEVEL_SECONDS, na.rm=TRUE),
            PERC_TIME_LEVEL=sum(TIME_LEVEL_SECONDS, na.rm=TRUE)/as.numeric(min(DESCENT_TIME_SECONDS)),
            CDO_ALT=ifelse(is.na(min((ALT_START+ALT_END)/2)), min(ALT_MAX), min((ALT_START+ALT_END)/2)),
            NBR_LVL_SEG=sum(nbr, na.rm=TRUE),
            CDO=ifelse(TIME_LEVEL_SECONDS==0, 1, 0)) %>%
  as.data.frame()
