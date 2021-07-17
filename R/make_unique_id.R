#' Utility function to generate a unique id for each segment of a trajectory
#'
#' @param .trjs_df dataframe of trajectory data
#' @param .max_dT maximum time offset before considering multiple legs (default = 500 sec = )
#'
#' @return dataframe with appended unique id
#' @export
#'
#' @examples
#' \donotrun{
#' make_unique_id(trajectory_dataframe)
#' }
make_unique_id <- function(.trjs_df, .max_dT = 500){
  df <- .trjs_df %>%
    dplyr::group_by(ICAO24, FLTID) %>%
    dplyr::arrange(TIME, .by_group = TRUE) %>%
    dplyr::mutate( dT  = TIME - lag(TIME, default = dplyr::first(TIME))
                  ,LEG = 0) %>%        # set default value
  # if there is a dT >= max_dT create new leg
    dplyr::mutate( LEG = if_else(dT >= .max_dT, 1, 0)
                  ,LEG = cumsum(LEG)   # create leg counter fill
                  )
  df <- df %>% # could not get ungroup() to work in pipe
    dplyr::ungroup() %>%
  # uid := paste()
    dplyr::mutate(UID = paste0(ICAO24,"-", FLTID,"-", lubridate::date(DOF),"-",LEG)) %>%
  # sort and return
    dplyr::select(UID, ICAO24, FLTID, ADEP, ADES, TIME, LAT, LON, ALT, dplyr::everything())
  return(df)
}
