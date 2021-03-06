#' @title Check user input and start an optimization
#' @name windfarmGA
#' @description The initiating function of an optimization run which
#' will interactively check user-inputs. If all inputs are correct,
#' an optimization will be started.
#'
#' @details A terrain effect model can be included in the optimization process.
#' Therefore, an SRTM elevation model will be downloaded automatically via the
#' \code{raster::getData} function. A land cover raster can also be downloaded
#' automatically from the EEA-website, or the path to a raster file can be 
#' passed to \code{sourceCCL}. The algorithm uses an adapted version of the
#' Raster legend ("clc_legend.csv"), which is stored in the package directory 
#' \file{~/inst/extdata}. To use other values for the land cover roughness 
#' lengths, insert a column named \strong{"Rauhigkeit_z"} to the .csv file, 
#' assign a surface roughness length to all land cover types. 
#' Be sure that all rows are filled with numeric values and save the file
#' with \strong{";"} separation. Assign the path of the file to the 
#' input variable \code{sourceCCLRoughness} of this function.
#'
#' @export
#' @seealso \code{\link{genAlgo}} 
#' 
#' @useDynLib windfarmGA, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom rgdal readOGR
#' @importFrom sp Polygon SpatialPolygons CRS proj4string spTransform
#' @importFrom raster plot crs
#' @importFrom utils globalVariables
#' @importFrom graphics plot.new title
#'
#' @inheritParams genAlgo
#' 
#' @return The result is a matrix with aggregated values per generation,
#' the best individual regarding energy and efficiency per generation,
#' some fuzzy control variables per generation, a list of all fitness values
#' per generation, the amount of individuals after each process, a matrix of
#' all energy, efficiency and fitness values per generation, the selection and 
#' crossover paramters, a matrix with the generational difference in maximum
#' and mean energy output, a matrix with the given inputs, a dataframe with
#' the wind information, the mutation rate per generation and matrix with all 
#' tested wind farm layouts. 
#'
#' @author Sebastian Gatscha
utils::globalVariables(
  c(
    "X","Y",
    "var1.pred","x","y",
    "element_rect","element_line",
    "unit", 
    "srtm_crop", "cclRaster", "weibullsrc",
    "cl",
    "k" 
    # ,"proj4string" 
    # ,"`proj4string<-`"
    ))


windfarmGA <- function(dns, layer, Polygon1, GridMethod, Projection, 
                       sourceCCL, sourceCCLRoughness,
                       vdirspe, Rotor = 30, fcrR = 3, n = 10, topograp = FALSE,
                       iteration = 100, referenceHeight = 50,
                       RotorHeight = 50, SurfaceRoughness = 0.14, 
                       Proportionality = 1, mutr = 0.001, 
                       elitism = TRUE, nelit = 6,
                       selstate = "FIX", crossPart1 = "EQU", trimForce = TRUE, 
                       weibull, weibullsrc,
                       Parallel, numCluster, verbose = FALSE, plotit = FALSE) {

  opar = par(no.readonly = TRUE)
  on.exit(par(opar))
  par(mfrow = c(1,2), ask = FALSE)
  ######## CHECK INPUT POLYGON
  ## Check if Polygon given is correctly
  if (!missing(Polygon1)) {
    if (!missing(Projection)) {
      Polygon1 <- isSpatial(Polygon1, Projection)
    } else {
      Polygon1 <- isSpatial(Polygon1)
    }
    plot(Polygon1, col = "red", main = "Original Input Shapefile");
    title(sub = Polygon1@proj4string, line = 1)
    readline(prompt = "\nPress <ENTER> if this is your Polygon")
  }
  ## Load Polygon from a Source File. Just if dns and layer are not missing.
  if (!missing(dns) & !missing(layer)) {
    # Input the Source of the desired Polygon
    Polygon1 <- rgdal::readOGR(dsn = dns, layer = layer)
    plot(Polygon1, col = "red", main = "Original Input Shapefile")
    title(sub = Polygon1@proj4string, line = 1)
    readline(prompt = "\nPress <ENTER> if this is your Polygon")
  }
  ##  Project the Polygon to LAEA if it is not already.
  if (is.na(sp::proj4string(Polygon1))) {
    cat("Polygon is not projected. Lambert Azimuthal Equal Area Projection is used.\n")
    Projection = "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
    +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
    sp::proj4string(Polygon1) <- CRS(Projection)
  }
  if (missing(Projection)) {
    cat("No Projection is given. Take Lambert Azimuthal Equal Area Projection.\n")
    Projection = "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
    +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  } else {
    Projection <- Projection
  }
  if (as.character(raster::crs(Polygon1)) != Projection) {
    Polygon1 <- sp::spTransform(Polygon1, CRSobj = Projection)
  }
  plot(Polygon1, col = "red", main = "Projected Input Shapefile")
  title(sub = Polygon1@proj4string, line = 1)
  readline(prompt = "\nPress <ENTER> if this is your Polygon")

  ######## CHECK INPUT GENETIC ALGORITHM
  ## Check if Crossover Method is chosen correctly.
  if (missing(crossPart1)) {crossPart1 <- readinteger()}
  if (crossPart1 != "EQU" & crossPart1 != "RAN") {
    crossPart1 <- readinteger()
  }
  ## Check if Selection Method is chosen correctly.
  if (missing(selstate)) {selstate <- readinteger()}
  if (selstate != "FIX" & selstate != "VAR") {
    selstate <- readintegerSel()
  }

  ## Check if Input Wind data is given correctly.
  if (missing(vdirspe)) {
    stop("\n##### No wind data.frame is given. \nThis input is required for an optimization run")
  }
  plot.new()
  plotWindrose(data = vdirspe, spd = vdirspe[, 'ws'], dir = vdirspe[, 'wd'])
  readline(prompt = "\nPress <ENTER> if the windrose looks correct?")
  ## Check if Rotor,fcrR,n,iteration,RotorHeight,
  ## SurfaceRoughness,Proportionality,mutr,nelit are numeric
  ChekNumer <- is.numeric(c(Rotor, n, fcrR, iteration, referenceHeight, 
                            RotorHeight, SurfaceRoughness, Proportionality, mutr, nelit))
  if (ChekNumer == FALSE) {
    cat("################### GA WARNING MESSAGE ###################")
    stop("\n##### A required numeric input is not numeric.\n
         See documentation.")
  }
  ## Check if topograp,elitism,trimForce are logical
  ChekLogic <- is.logical(c(topograp, elitism, trimForce))
  if (ChekLogic == FALSE) {
    cat("################### GA WARNING MESSAGE ###################")
    stop("\n##### A required logical input is not logical.\n
         See documentation.")
  }
  ## Check if Grid with given inputs is correctly
  if (missing(GridMethod)) {
    GridMethod <- "Rectangular"
  }
  GridMethod <- toupper(GridMethod)
  ## Decide if the space division should be rectangular or in hexagons.
  if (GridMethod == "HEXAGON" | GridMethod == "H") {
    Grid <- HexaTex(Polygon1 = Polygon1, 
                    size = (Rotor * fcrR) / 2, plotTrue = TRUE)
  } else {
    Grid <- GridFilter(shape = Polygon1,resol = (Rotor * fcrR), 
                       prop = Proportionality, plotGrid = TRUE)
  }
  cat("\nIs the grid spacing appropriate?")
  InputDaccor <- readline(prompt = "Type 'ENTER' if the the grid is corrent and 'n' if you like to change some inputs.")
  InputDaccor <- tolower(InputDaccor)
  if  (InputDaccor == "n") {
    cat("################### GA WARNING MESSAGE ###################")
    stop("\n##### The grid spacing is not as required. \n
             Adjust radius (Rotor) or fraction of the radius (fcrR) or the reference system.\n
             You can also use the function GridFilter first, to see the resulting grid with given inputs.\n
             Be carefull, with GridFilter you have to give a resolution as input, in this case this will be fcrR*Rotor.
             ")
  }


  if (missing(topograp)) {
    topograp <- FALSE
  }    
  if (missing(weibull)) {
    weibull <- FALSE
  }  
  if (weibull) {
    cat("\nWeibull Distribution is used.")
    if (missing(weibullsrc)) {
      cat("\nWeibull Informations from package will be used.\n")
    } else {
      cat("\nWeibull Informations are given.\n")
      if (!class(weibullsrc) == "list") {
        cat(paste("weibullsrc class: \n1 - ", class(weibullsrc)))
        stop("\n'weibullsrc' must be a list with two rasters. List item 1 should be the shape parameter (k) raster
            and list item 2 should be the scale parameter (a) raster of a weibull distribution.")
      }
      if (!class(weibullsrc[[1]])[1] == "RasterLayer" | !class(weibullsrc[[2]])[1] == "RasterLayer" ) {
        cat(paste("list item classes: \n1 - ", class(weibullsrc[[1]]), "\n2 - ", class(weibullsrc[[2]])))
        stop("\nOne of the given list items is not a raster.")
      }
      weibullsrc <- weibullsrc
    }
  }
  if (missing(weibullsrc)) {
    weibullsrc <- ""
  }
  if (missing(Parallel)) {
    Parallel <- FALSE
  }
  if (missing(numCluster)) {
    numCluster <- 1
  }
  if (Parallel == TRUE) {
    numPossClus <- as.integer(Sys.getenv('NUMBER_OF_PROCESSORS'))
    if (numPossClus == 1) {
      cat("\nOnly 1 core is available. Set Parallel to FALSE")
      numCluster <- 1
      Parallel <- FALSE
    } 
    if (numCluster > numPossClus) {
      cat("\nNumber of clusters is bigger than the amount of available cores. Reduce to max.")
      numCluster <- numPossClus
    }
  }

  ##########################################################
  ############### RUNNING GENETIC ALGORITHM
  result <- genAlgo(Polygon1 = Polygon1, GridMethod = GridMethod, 
                    Rotor = Rotor, n = n, fcrR = fcrR, iteration = iteration,
                    vdirspe = vdirspe, topograp = topograp,
                    referenceHeight = referenceHeight, RotorHeight = RotorHeight, 
                    SurfaceRoughness = SurfaceRoughness, 
                    Proportionality = Proportionality,
                    mutr = mutr, elitism = elitism, nelit = nelit,
                    selstate = selstate, crossPart1 = crossPart1, 
                    trimForce = trimForce,
                    Projection = Projection, sourceCCL = sourceCCL, 
                    sourceCCLRoughness = sourceCCLRoughness,
                    weibull = weibull, weibullsrc = weibullsrc, 
                    Parallel = Parallel, numCluster = numCluster,
                    verbose = verbose, plotit = plotit)

  invisible(result)
}

