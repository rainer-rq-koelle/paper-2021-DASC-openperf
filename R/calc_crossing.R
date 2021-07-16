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
extract_pos_at_distance_from_point <- function(.trj_df, .pt, .dist, .col_name = CX){
  dist_NM_m <- .dist * 1852
  pos <- .trj_df %>%
    mutate(DIST = geosphere::distHaversine(cbind(LON, LAT), .pt)) %>%
    filter(between(DIST, dist_NM_m - 200, dist_NM_m + 200 )) %>%
    group_by(UID) %>%
    mutate(DIST2 = abs(DIST - dist_NM_m))%>%
    filter(DIST2 == min(DIST2))
  pos <- pos %>% rename({{.col_name}} := DIST)
  return(pos)
}
