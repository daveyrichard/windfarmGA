#' @title Create a random initial Population
#' @name StartGA
#' @description  Create \code{nStart} random sub-selections from the
#' indexed grid and assign binary variable 1 to selected grids.
#' This function initiates the genetic algorithm with a first random
#' population and will only be needed in the first iteration.
#' 
#' @export
#' 
#' @param Grid The data.frame output of "GridFilter" function,
#' with X and Y coordinates and Grid cell IDs.
#' @param n A numeric value indicating the amount of required turbines.
#' @param nStart A numeric indicating the amount of randomly generated
#' initial individuals. Default is 100.
#'
#' @return Returns a list of \code{nStart} initial individuals,
#' each consisting of \code{n} turbines.
#' Resulting list has the x and y coordinates, the grid cell ID
#' and a binary variable of 1, indicating a turbine in the grid cell.
#' 
#' @examples
#' library(sp)
#' ## Exemplary input Polygon with 2km x 2km:
#' Polygon1 <- Polygon(rbind(c(0, 0), c(0, 2000),
#' c(2000, 2000), c(2000, 0)))
#' Polygon1 <- Polygons(list(Polygon1),1);
#' Polygon1 <- SpatialPolygons(list(Polygon1))
#' Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
#' +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#' proj4string(Polygon1) <- CRS(Projection)
#' plot(Polygon1,axes=TRUE)
#'
#' Grid <- GridFilter(Polygon1,200,1,"TRUE")
#'
#' ## Create 5 individuals with 10 wind turbines each.
#' firstPop <- StartGA(Grid = Grid[[1]], n = 10, nStart = 5)
#' str(firstPop)
#'
#' @author Sebastian Gatscha
StartGA           <- function(Grid, n, nStart = 100) {
  if (length(Grid[,'ID']) <= n) {
    cat("\n################### GA ERROR MESSAGE ###################\n")
    cat(paste("##### Amount Grid-cells: ", length(Grid[,'ID']),
              "\n##### Amount of turbines: ", n, "\n"))
    stop("The amount of Grid-cells is smaller or equal the number of turbines requested.\n",
         "Decrease Resolution (fcrR), number of turbines (n), or Rotorradius (Rotor).")
  }
  if (length(Grid[,'ID']) < (2*n)) {
    cat("\n################### GA ERROR MESSAGE ###################\n")
    cat(paste("##### Amount Grid-cells: ", length(Grid[, 'ID']),
              "\n##### Amount of turbines: ", n, "\n"))
    stop("The amount of Grid-cells should at least be double the size of turbines requested.\n",
         "Decrease Resolution (fcrR), number of turbines (n), or Rotorradius (Rotor).")
  }
  ## Assign Binary Variable 0 to all Grid cells
  Grid <- cbind(Grid, 'bin' = 0)
  ## Randomly sample n grid cells and assign 1 to bin column
  lapply(seq_len(nStart), function(i) {
    res <- Grid[Grid[,'ID'] %in% sample(x = Grid[,'ID'], size = n, replace = FALSE),]
    res[,'bin'] = 1L
    res
  })
}