#' Utility functions to cast lat/lon data frame/tibble to sf-points and/or linestring
#'
#' @return
NULL

#' @rdname cast_latlon_to_pts
#'
#' @param .df dataframe/tibble of lat/lon positions
#' @param .crs coordinate reference system (default: 4326 := WGS84)
#' @param .drop_coord remove (or keep) lat/lon columns (default: TRUE := remove, FALSE := keep)
#'
#' @return
#' @export
#'
#' @examples
#' \donotrun{
#' cast_latlon_to_pts(adsb_df)
#' }
cast_latlon_to_pts <- function(.df, .crs = 4326, .drop_coord = TRUE){
  pts_sf <- .df %>%
    sf::st_as_sf(coords = c("LON","LAT"), crs = .crs, remove = .drop_coord)
  return(pts_sf)
}

#' @rdname cast_pts_to_ls
#'
#' @return sf linestring
#'
#' @export
cast_pts_to_ls <- function(.pts_sf, .group_var){
  ls_sf <- .pts_sf %>%
    dplyr::group_by({{ .group_var}}) %>%
    dplyr::summarise(do_union = FALSE, .groups = "drop") %>%
    sf::st_cast("LINESTRING")
  return(ls_sf)
}

#' @rdname cast_latlon_to_ls
#'
#' @return sf linestring
#' @export
cast_latlon_to_ls <- function(.df, .crs = 4326, .drop_coord = TRUE, ...){
  pts_sf <- cast_latlon_to_pts(.df, .crs, .drop_coord)
  ls_sf  <- cast_pts_to_ls(pts_sf, .group_var = NULL)
}
