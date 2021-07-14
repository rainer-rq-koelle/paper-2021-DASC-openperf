#' Utility function to generate a unique id for each segment of a trajectory
#'
#' @param .trjs_df dataframe of trajectory data
#'
#' @return dataframe with appended unique id
#' @export
#'
#' @examples
#' \donotrun{
#' make_unique_id(trajectory_dataframe)
#' }
make_unique_id <- function(.trjs_df){
  df <- .trjs_df %>%
    dplyr::group_by(ICAO24, FLTID) %>%
    dplyr::arrange(TIME, .by_group = TRUE) %>%
    dplyr::mutate( dT  = TIME - lag(TIME, default = dplyr::first(TIME))
                  ,LEG = 0)     # set default value

  # if there is a dT of 5 min or more create new leg, ie. ifelse :=1, then cumsum
  # uid := paste ....

}
