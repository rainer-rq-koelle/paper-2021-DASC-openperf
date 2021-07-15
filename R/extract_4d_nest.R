#' Extract and nest 4D positions
#'
#' @param .trjs_df
#'
#' @return nested dataframe/tibble
#' @export
#'
#' @examples
extract_4d_nest <- function(.trjs_df){
  df <- .trjs_df %>%
    dplyr::select(UID, TIME, LAT, LON, ALT) %>%
    dplyr::group_by(UID) %>%
    tidyr::nest()
}
