
# Altitude outlier filter using median filter

library("zoo")

Alt_Outlier_filter=function(df, KernelSize, Fill, IntResults){
  df1=group_by(df, flight_id) %>%
    mutate(ALT_med=rollmedian(altitude, KernelSize, fill=NA),
           sq_eps=(altitude-ALT_med)^2,
           sigma=sqrt(rollmean(sq_eps, KernelSize, fill=NA)),
           Outlier=ifelse(sq_eps>sigma, 1, 0))
  # Choose if the outliers need to be filled by the median altitude
  if (Fill==TRUE) {
    df1=mutate(df1, altitude=ifelse((Outlier==0 | is.na(Outlier)), altitude, ALT_med))
  }
  # Choose if the intermediate results need to be returned in the dataframe
  if (IntResults==FALSE) {
    df1=select(df1, -ALT_med, -sq_eps, -sigma)
  }
  return(df1)
}
