#' Utility functions to determine airport context, runway system, etc
#'
#'
NULL

#' @rdname rwy_ctr_line
#'
#' @export
rwy_ctr_line <- function(.rwy_df = aip, .ctrl_length = 10000){
  df <- .rwy_df %>%
    filter(REF != "ARP") %>%
    select(REF, NAME, LAT, LON) %>%
    group_by(NAME) %>%
    mutate( LAT2 = case_when(!is.na(lag(LAT))  ~ lag(LAT)
                             ,!is.na(lead(LAT)) ~ lead(LAT))
            ,LON2 = case_when(!is.na(lag(LON))  ~ lag(LON)
                              ,!is.na(lead(LON)) ~ lead(LON))
    ) %>%
    # calculate "reverse" runway bearing with geosphere::bearingRhumb
    mutate( RBRG  = bearingRhumb(p1 = cbind(LON2, LAT2), p2 = cbind(LON, LAT))
    )

  # determine "endpoint" of extended centerline at d = 10000 meters
  tmp <- with(df, destPointRhumb(cbind(LON, LAT), b= RBRG, d = .ctrl_length)) %>%
    as_tibble() %>% rename(LON3 = lon, LAT3 = lat)

  # combine and return
  df <- df %>% bind_cols(tmp)
  return(df)
}


#' @rdname rwy_ctr_line_pts
#'
#' @export
rwy_ctr_line_pts <- function(.rwy_ctr_line, .debug = FALSE){
  # could not get pivot_longer work with multiple cols
  tmp1 <- .rwy_ctr_line %>% select("REF":"LON")

  # include opposite runway threshold
  tmp2 <- .rwy_ctr_line %>% select("REF","NAME", "LAT2","LON2") %>%
    rename(LAT = LAT2, LON = LON2)

  # centerline end point determined beforehand
  tmp3 <- .rwy_ctr_line %>% select("REF","NAME", "LAT3","LON3") %>%
    rename(LAT = LAT3, LON = LON3)

  if(.debug == TRUE){
    df <- bind_rows(tmp1, tmp2, tmp3)
  }else{
    df <- bind_rows(tmp1, tmp3)
  }

  df <- df %>% arrange(REF, NAME)
  return(df)
}

#' @rdname rwy_system_hull
#'
#' @return convex-hull polygon around runway system and extended centerlines
#' @export
rwy_system_hull <- function(.aip, .ctrl_length){
  rwys <- .aip %>% filter(TYPE == "THR") %>%
    rwy_ctr_line(.ctrl_length) %>%
    rwy_ctr_line_pts() %>%
    cast_latlon_to_pts() %>%
    sf::st_buffer(dist = 500) %>%
    sf::st_union() %>%
    sf::st_convex_hull()
  return(rwys)
}
