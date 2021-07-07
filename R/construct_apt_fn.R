#' Utility function for the European data preparation: identify and construct airport level data filename
#'
#' @param .apt 
#' @param .yr 
#' @param .pth 
#'
#' @return
#' @export
#'
construct_apt_fn <- function(.apt, .yr, .pth = "../__DATA/"){
  fn <- paste0(.pth, .apt,"/", .apt, "_", .yr,"_FACT.csv")
  return(fn)
}