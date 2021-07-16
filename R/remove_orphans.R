#' Utility function to remove orphans or partial legs/trajectory segments
#'
#' @param .trjs_df dataframe/tibble of trajectories
#' @param .min_n minimum number of position reports
#'
#' @return cleaned dataframe/tibble
#' @export
#'
#' @examples
#' \donotrun{
#' remove_orphans(adsbdata)
#' }
remove_orphans <- function(.trjs_df, .min_n = 300){
  orphans <- .trjs_df %>%
    dplyr::group_by(UID) %>%
    dplyr::summarise(N = dplyr::n(), .groups = "drop") %>%
    dplyr::filter(N <= .min_n)

  no_orphans <- .trjs_df %>%
    filter(!UID %in% orphans$UID)
  return(no_orphans)
}
