#' Utility function to identify crossing based on distance from a point
#'
#'
NULL

#' @rdname df_to_geo_lonlat
#'
#' @return geo point for geoshere in LON/LAT order
#' @export
df_to_geo_lonlat <- function(.df){
  geo <- c(.df$LON, .df$LAT )
  return(geo)
}

#' @rdname extract_pos_at_distance_from_point
#'
#' @return
#' @export
extract_pos_at_distance_from_point <- function(.trj_df, .pt, .dist, .prefix = paste0("C", .dist), .debug = NULL){
#  print(paste0("\n " , .debug))
  dist_NM_m <- .dist * 1852
  # determine and check for distance from point
  pos <- .trj_df %>%
    mutate(DIST = geosphere::distHaversine(cbind(LON, LAT), .pt)) %>%
    filter(between(DIST, dist_NM_m - 500, dist_NM_m + 500 ))
  # catch empty distances
  if(nrow(pos) == 0){
#    print(paste0("\n " , .debug, "  entered nrow == 0"))
    pos <- tibble(TIME = NA, BRG = NA)
  }else{
#    print(paste0("\n " , .debug, "  entered else"))
    pos <- pos %>%
      mutate(DIST2 = abs(DIST - dist_NM_m))%>%
      filter(DIST2 == min(DIST2) ) %>%
      filter(TIME == max(TIME)   ) # last entry
    pos <- pos %>% rename(OFFSET = DIST2) %>%
  # calculate bearing to intersection
      mutate(BRG = geosphere::bearingRhumb(.pt, c(pos$LON, pos$LAT)))
  }
#  print(paste0("\n " , .debug, "  outside ifelse"))
  pos <- pos %>%
    select(TIME, BRG, dplyr::everything()) %>%
  # nice col names using glue like notation for quoted variables
  rename_with(.fn = ~ paste0({.prefix},"_", .))
  return(pos)
}


# debug trouble shoot
extract_pos_at_distance_from_point2 <- function(.trj_df, .pt, .dist, .prefix = paste0("C", .dist), .debug = NULL){
  print(paste0("\n " , .debug))
  dist_NM_m <- .dist * 1852
  # determine and check for distance from point
  pos <- .trj_df %>%
    mutate(DIST = geosphere::distHaversine(cbind(LON, LAT), .pt)) %>%
    filter(between(DIST, dist_NM_m - 500, dist_NM_m + 500 ))
return(pos)
}
