#' Read csv files switching csv and csv2
#' 
#' Utility function wrapper for readr::read_csv and readr::read_csv2.
#' Function tests the csv file and then picks the respective parser csv or csv2.
#'
#' @param .fn filename (including file path)
#' @param .colspec optional reading of selective columns
#' @param ... 
#'
#' @return
#' @export
#'
#' @examples
read_csv12 <- function(.fn, .colspec = NULL, ...){
  # test for csv or csv2
  tst <- readr::read_csv(.fn, n_max = 3)
  siz <- dim(tst)[2]   # dim[2] == 1 for semicolon as read_csv expects comma
  
  # read data files
  if(siz > 1){
    df <- readr::read_csv(.fn, col_types = .colspec)
  }else{
    df <- readr::read_csv2(.fn, col_types = .colspec)
  }
  return(df)
}