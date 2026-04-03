#' extract_maturity
#'
#' @description A helper function to extract maturity number from series (e.g., CL01 -> 1)
#'
#' @param series A character vector of series names
#'
#' @return A numeric vector of maturity months
#'
#' @noRd
extract_maturity <- function(series) {
  as.numeric(gsub("[A-Z]+", "", series))
}
