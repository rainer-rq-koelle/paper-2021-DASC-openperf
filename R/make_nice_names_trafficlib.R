#' Rename columns with standard naming convention
#'
#' @param .df
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' make_nice_names_trafficlib(downloadeddataframe)
#' }
make_nice_names_trafficlib <- function(.df){
  df <- .df %>%
    rename(  TIME   = timestamp
            ,ICAO24 = icao24
            ,FLTID  = callsign
            ,ADEP   = origin
            ,ADES   = destination
            ,LAT    = latitude
            ,LON    = longitude
            ,ALT    = altitude
            ,ALT_G  = geoaltitude
            ,GS     = groundspeed
            ,DOF    = day
    )
  return(df)
}
