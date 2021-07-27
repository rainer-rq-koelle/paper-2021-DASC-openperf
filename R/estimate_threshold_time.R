#' Estimate time at landing threshold
#'
NULL

#' @rdname rwy_to_number
#'
#'coerce runway id to heading
#'
#' @return landing runway direction
#' @export
rwy_to_number <- function(.rwy){
  rwy_dir <- gsub("\\D","", .rwy) # strip non-digets and replace with empty
  rwy_dir <- ((as.numeric(rwy_dir) * 10) + 360) %% 360
}

#' @rdname estimate_threshold_time
#'
#' estimation of time over threshold based on last position before threshold and associated ground speed
#'
#' @param .trjs_latlon
#' @param .debug
#'
#' @return
#' @export
estimate_threshold_time <- function(.trjs_latlon, .debug = FALSE){
  last_pos <- .trjs_latlon %>%
    mutate(DIST_THR = distHaversine(cbind(LON, LAT), cbind(LON_THR,LAT_THR))
           , BRG_THR = bearingRhumb( cbind(LON, LAT), cbind(LON_THR, LAT_THR))
           , BEFORE  = abs(BRG_THR - rwy_to_number(RWY)) < 30
           , COASTG  = DIST_THR == lag(DIST_THR)
           , V_GND   = (lag(DIST_THR) - DIST_THR) / as.numeric(TIME - lag(TIME))
           , V_GND_SM= zoo::rollmean(V_GND, k = 9, fill = NA, align = "right")
    ) %>%
    # cut-off any position after the start of coasting
    # or if there are positions post threshold ~ BRG <> landing direction
    filter(COASTG == FALSE & BEFORE == TRUE )

  last_15 <- last_pos %>% tail(n = 15)
  avg_final_app_speed <- mean(last_15$V_GND_SM, na.rm = TRUE)   # for some LSZH arrivals only a few points and smooth NAs

  thr_row <- last_pos %>% tail(n = 1) %>%
    mutate(LAT = LAT_THR, LON = LON_THR
           ,TIME = TIME + ceiling(DIST_THR / avg_final_app_speed)  # round up for complete secs
           ,DIST_THR = 0                                           # @ threshold!
    )
  if(.debug == FALSE) thr_row <- thr_row %>% pull(TIME)
  return(thr_row)
}
