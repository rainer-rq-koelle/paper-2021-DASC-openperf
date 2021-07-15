#' Utility function to identify landing runway
#'
#' @param .trj_pts trajectory sf-points
#' @param .rwy_ctrl_ls linestring of extended rwy centerline
#' @param .ctrl_offset alignment offset
#'
#' @return
#' @export
#'
#' @examples
identify_rwy <- function(.trj_pts, .rwy_ctrl_ls, .ctrl_offset = 100){
  # stop if nots
  tmp <- sf::st_join(
       .rwy_ctrl_ls, .trj_pts
      , join = sf::st_is_within_distance, dist = .ctrl_offset) %>%
    sf::st_drop_geometry() %>%        # keep just the "spatially joined" dataframe
    na.omit() %>%                 # eliminate no hits
    dplyr::group_by(REF) %>%
    dplyr::summarise(N = dplyr::n(), .groups = "drop") %>%
    dplyr::mutate(
       TOT   = sum(N, na.rm = TRUE)       # na.rm should not be necessary
      ,TRUST = N / TOT)                   # share in case several runways

  return(tmp)
}
