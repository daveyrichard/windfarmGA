########################################
#' @title cansee
#' @name cansee
#' @description Check if point1 (xy1) visible from point2 (xy2) given 
#' a certain DEM (r)
#'
#' @export
#'
#' @param r A DEM raster
#' @param xy1 A vector/matrix with X and Y coordinates for Point 1
#' @param xy2 A vector/matrix with X and Y coordinates for Point 2
#' @param h1 A numeric giving the extra height offset of Point 1
#' @param h2 A numeric giving the extra height offset of Point 2
#'
#' @return A boolean value, indicating if the point (xy2) is visible
#'
#' @author Sebastian Gatscha
cansee <- function(r, xy1, xy2, h1=0, h2=0){
  # xy1 = c(4653100.36021378, 2744048.65794167); 
  # xy2 = c(4648381.88040377, 2741196.10301024);
  
  # xy1 = xy1; xy2 = xy2[1,]

  ### can xy1 see xy2 on DEM r?
  ### r is a DEM in same x,y, z units
  ### xy1 and xy2 are 2-length vectors of x,y coords
  ### h1 and h2 are extra height offsets
  ###  (eg top of mast, observer on a ladder etc)
  xyz = rasterprofile(r, xy1, xy2)
  np = length(xyz[,1])-1
  h1 = xyz[["z"]][1] + h1
  h2 = xyz[["z"]][np] + h2
  hpath = h1 + (0:np)*(h2-h1)/np
  invisible(!any(hpath < xyz[["z"]], na.rm = T))
}


#' @title viewTo
#' @name viewTo
#' @description Check if Point 1 (xy) is visible from multiple points
#' (xy2)
#'
#' @export
#' @importFrom plyr aaply
#' 
#' @param r A DEM raster
#' @param xy1 A matrix with X and Y coordinates for Point 1
#' @param xy2 A matrix with X and Y coordinates for Points 2
#' @param h1 A numeric giving the extra height offset of Point 1
#' @param h2 A numeric giving the extra height offset of Point 2
#' @param progress Is passed on to plyr::aaply
#'
#' @return A boolean vector, indicating if Point 1 (xy1) is visible
#' from all elements of Points 2 (xy2)
#'
#' @author Sebastian Gatscha
#' 
viewTo <- function(r, xy1, xy2, h1=0, h2=0, progress="none"){
  # xy1 = c(x = 4653100.36021378, y = 2744048.65794167); 
  # xy2 = structure(c(4648381.88040377, 4649001.7726914, 4649621.66497904, 
  #                   4650241.55726667, 4650861.4495543, 4648381.88040377, 2741196.10301024, 
  #                   2741196.10301024, 2741196.10301024, 2741196.10301024, 2741196.10301024, 
  #                   2741815.99529787), .Dim = c(6L, 2L), .Dimnames = list(NULL, c("x1", 
  #                                                                                 "x2")))
  
  # xy1 = turbine_locs[1,]; xy2 = sample_xy; h1=h2=0
  
  ## xy2 is a matrix of x,y coords (not a data frame)
  a <- plyr::aaply(xy2, 1, function(d){
    cansee(r,xy1 = xy1,xy2 = d,h1,h2)}, .progress=progress)
  a[is.na(a)] <- FALSE
  return(a)
}


#' @title rasterprofile
#' @name rasterprofile
#' @description Sample a raster along a straight line between 2 points
#'
#' @export
#' @importFrom raster res cellFromXY
#' @importFrom stats complete.cases
#'
#' @param r A DEM raster
#' @param xy1 A matrix with X and Y coordinates for Point 1
#' @param xy2 A matrix with X and Y coordinates for Points 2
#' @param plot Plot the process? Default is FALSE
#'
#' @return A boolean vector, indicating if Point 1 (xy1) is visible
#' from all elements of Points 2 (xy2)
#'
#' @author Sebastian Gatscha
rasterprofile <- function(r, xy1, xy2, plot=FALSE){
  # r = DEM_meter[[1]]; xy1 = sample_xy[29,]; xy2 = sample_xy[26,]; plot=T
  
  if (plot==TRUE) {
    plot(r)
    points(x = xy2[1], y=xy2[2], col="blue", pch=20, cex=1.4)
    points(x = xy1[1], y=xy1[2], col="red", pch=20, cex=2)
  }
  
  ### sample a raster along a straight line between two points
  ### try to match the sampling size to the raster resolution
  dx = sqrt( (xy1[1]-xy2[1])^2 + (xy1[2]-xy2[2])^2 )
  nsteps = 1 + round(dx/ min(raster::res(r)))
  xc = xy1[1] + (0:nsteps) * (xy2[1]-xy1[1])/nsteps
  yc = xy1[2] + (0:nsteps) * (xy2[2]-xy1[2])/nsteps
  
  if (plot==TRUE) {
    points(x = xc, y=yc, col="red", pch=20, cex=1.4)
  }
  
  rasterVals <- r[raster::cellFromXY(r, cbind(xc,yc))]
  # rasterVals <- raster::extract(x = r, y = cbind(xc,yc), buffer=5, df=T)
  # rasterVals <- rasterVals[!is.na(rasterVals)]
  
  pointsZ <- data.frame(x = xc, y = yc, z = rasterVals)
  
  if (plot==TRUE) {
    points(pointsZ$x, pointsZ$y, pch=20, col="black")
    text(pointsZ$x, pointsZ$y, pos=1, pointsZ$z, cex=0.5)
  }
  
  if (any(is.na(pointsZ))) {
    pointsZ <- pointsZ[stats::complete.cases(pointsZ),]
    # browser()
  }
  return(pointsZ)
}


#' @title viewshed
#' @name viewshed
#' @description Calculate visibility for given points in 
#' a given area.
#'
#' @export
#' 
#' @importFrom sp coordinates spsample
#' @importFrom raster res ncell
#' @importFrom plyr aaply
#' @importFrom sf st_as_sf

#' @param r A DEM raster
#' @param shape A SpatialPolygon of the windfarm area.
#' @param turbine_locs Coordinates or SpatialPoint representing
#' the wind turbines
#' @param h1 A numeric giving the extra height offset of Point 1
#' @param h2 A numeric giving the extra height offset of Point 2
#' @param progress Is passed on to plyr::aaply
#' 
#' @return A list of 5, containing the boolean result for every cell, 
#' the raster cell points, a SimpleFeature Polygon of the given area 
#' and the DEM raster
#' 
#' @examples \dontrun{
#' library(sp)
#' Polygon1 <- Polygon(rbind(c(4488182, 2667172), c(4488182, 2669343),
#'                           c(4499991, 2669343), c(4499991, 2667172)))
#' Polygon1 <- Polygons(list(Polygon1), 1);
#' Polygon1 <- SpatialPolygons(list(Polygon1))
#' Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
#' +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#' proj4string(Polygon1) <- CRS(Projection)
#' DEM_meter <- getDEM(Polygon1)
#' 
#' sample_POI <- spsample(DEM_meter[[2]], n = ncell(DEM_meter[[1]]), type = "regular")
#' sample_xy <- coordinates(sample_POI)
#' 
#' turbloc = spsample(DEM_meter[[2]], 10, type = "random");
#' res <- viewshed(r = DEM_meter[[1]], shape=DEM_meter[[2]], turbine_locs = turbloc,  h1=1.8, h2=50)
#' }
#' @author Sebastian Gatscha
viewshed <- function(r, shape, turbine_locs, h1=0, h2=0, progress="none"){
  # r = DEM_meter[[1]]; shape=DEM_meter[[2]]; turbine_locs = turbloc
  # h1=0; h2=0; progress="none"
  
  if (class(shape)[1] == "sf") {
    shape <- as(shape, "Spatial")  
  }
  if (class(turbine_locs) == "SpatialPoints") {
    turbine_locs = sp::coordinates(turbine_locs)
  }
  
  smplf <- sf::st_as_sf(shape)
  smplf <- sf::st_buffer(smplf, dist = 10)
  shape <- as(smplf, "Spatial")  
  
  
  sample_POI <- sp::spsample(shape, n = raster::ncell(r), type = "regular")
  sample_xy <- sp::coordinates(sample_POI)
  
  ## xy2 is a matrix of x,y coords (not a data frame)
  res <- plyr::aaply(turbine_locs, 1, function(d){
    viewTo(r, xy1 = d, xy2 = sample_xy, h1, h2)
  }, .progress=progress)
  
  
  if (is.matrix(res)) {
    res <- res[1:nrow(res),1:nrow(sample_xy)]
  }
  if (is.logical(res)) {
    res[1:nrow(sample_xy)]
  }
  
  return(list("Result"=res, "Raster_POI" = sample_xy, 
              "Area" = sf::st_as_sf(shape), "DEM" = r, "Turbines" = turbine_locs))
}
## Geht noch nicht
# viewshed_par <- function(r, shape, turbine_locs, h1=0, h2=0, progress="none"){
#   # r = DEM_meter; shape=shape_meter; turbine_locs = turbloc
#   # h1=0; h2=0;
#   
#   if (class(shape)[1] == "sf") {
#     shape <- as(shape, "Spatial")  
#   }
#   if (class(turbine_locs) == "SpatialPoints") {
#     turbine_locs = sp::coordinates(turbine_locs)
#   }
#   
#   sample_POI <- sp::spsample(shape, n = raster::ncell(r), type = "regular")
#   sample_xy <- sp::coordinates(sample_POI)
#   
#   
#   library(parallel)
#   nCore <- parallel::detectCores()
#   cl <- parallel::makeCluster(nCore)
#   parallel::clusterEvalQ(cl, {
#     library(plyr)
#     library(raster)
#   })
#   parallel::clusterExport(cl, varlist = c("turbine_locs", "sample_xy", 
#                                 "viewTo", "cansee", "rasterprofile", 
#                                 "r", "h1", "h2", "progress"))
#   
#   res <- parallel::parApply(cl = cl, X = turbine_locs, 1, function(d){
#     viewTo(r, xy1 = d, xy2 = sample_xy, h1, h2, progress)
#   })
#   res <- t(res)
#   
#   parallel::stopCluster(cl)
#   
#   if (is.matrix(res)) {
#     res <- res[1:nrow(res),1:nrow(sample_xy)]
#   }
#   if (is.logical(res)) {
#     res[1:nrow(sample_xy)]
#   }
#   
#   return(list("Result"=res, "Raster_POI" = sample_xy, 
#               "Area" = sf::st_as_sf(shape), "DEM" = r, "Turbines" = turbine_locs))
# }
# res <- viewshed_par(r = DEM_meter, shape=shape_meter, turbine_locs = turbloc,  h1=1.8, h2=50)


#' @title plot_viewshed
#' @name plot_viewshed
#' @description Plot the result of viewshed
#'
#' @export
#' 
#' @importFrom raster plot
#' @importFrom sf st_geometry
#' 
#' @param res The resulting list from viewshed
#' @param legend Plot a legend? Default is FALSE
#' 
#' @return NULL
#' @examples \dontrun{
#' library(sp)
#' library(raster)
#' Polygon1 <- Polygon(rbind(c(4488182, 2667172), c(4488182, 2669343),
#'                           c(4499991, 2669343), c(4499991, 2667172)))
#' Polygon1 <- Polygons(list(Polygon1), 1);
#' Polygon1 <- SpatialPolygons(list(Polygon1))
#' Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
#' +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#' proj4string(Polygon1) <- CRS(Projection)
#' DEM_meter <- getDEM(Polygon1)
#' 
#' sample_POI <- spsample(DEM_meter[[2]], n = ncell(DEM_meter[[1]]), type = "regular")
#' sample_xy <- coordinates(sample_POI)
#' 
#' turbloc = spsample(DEM_meter[[2]], 10, type = "random");
#' res <- viewshed(r = DEM_meter[[1]], shape=DEM_meter[[2]], turbine_locs = turbloc,  h1=1.8, h2=50)
#' plot_viewshed(res)
#' }
#' @author Sebastian Gatscha
plot_viewshed <- function(res, legend=FALSE) {
  # r=DEM_meter[[1]]; leg=TRUE
  raster::plot(res[[4]])
  plot(sf::st_geometry(res[[3]]), add = T)
  points(res[[2]], col="green", pch=20)
  points(res[[5]], cex=1.5, col="black", pch=20)
  if (is.matrix(res[[1]])) {
    invisible(apply(res[[1]], 1, function(d) {points(res[[2]][d,], col="red", pch=20)}))
  } else {
    points(res[[2]][res[[1]],], col="red", pch=20)
    # invisible(apply(res[[1]], 1, function(d) {points(res[[2]][d,], col="red", pch=20)}))
  }
  if (legend) {
    legend(x = "bottomright", y = "topleft", yjust=0, title="Visibility", 
           col=c("green","black", "red"), 
           legend = c("Not visible","Turbines","Turbine/s visible"), pch=20)    
  }
  
}




#' @title interpol_view
#' @name interpol_view
#' @description Plot an interpolated view of the viewshed analysis
#'
#' @export
#' 
#' @importFrom raster plot rasterize
#' @importFrom stats quantile
#' 
#' @param res The result list from viewshed.
#' @param plot Should the result be plotted? Default is TRUE
#' @param breakseq The breaks for value plotting. By default, 5 equal 
#' intervals are generated.
#' @param breakform If 'breakseq' is missing, a sampling function to 
#' calculate the breaks, like \code{\link{quantile}}, fivenum, etc.
#' @param plotDEM Plot the DEM? Default is FALSE
#' @param fun Function used for rasterize. Default is mean
#' @param ... Arguments passed on to \code{\link[raster]{plot}}.
#' 
#' @return An interpolated raster
#' 
#' @examples \dontrun{
#' library(sp)
#' library(raster)
#' Polygon1 <- Polygon(rbind(c(4488182, 2667172), c(4488182, 2669343),
#'                           c(4499991, 2669343), c(4499991, 2667172)))
#' Polygon1 <- Polygons(list(Polygon1), 1);
#' Polygon1 <- SpatialPolygons(list(Polygon1))
#' Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
#' +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#' proj4string(Polygon1) <- CRS(Projection)
#' DEM_meter <- getDEM(Polygon1)
#' 
#' sample_POI <- spsample(DEM_meter[[2]], n = ncell(DEM_meter[[1]]), 
#'                        type = "regular")
#' sample_xy <- coordinates(sample_POI)
#' 
#' turbloc = spsample(DEM_meter[[2]], 10, type = "random");
#' res <- viewshed(r = DEM_meter[[1]], shape=DEM_meter[[2]], 
#'                 turbine_locs = turbloc,  h1=1.8, h2=50)
#' interpol_view(res, plotDEM = T)
#' 
#' interpol_view(res, breakseq = seq(0,max(colSums(res$Result)),1))
#' interpol_view(res, plotDEM = F, breakform = quantile)
#' interpol_view(res, breakform = factor)
#' 
#' ## ... Arguments are past on to the raster plot method
#' interpol_view(res, plotDEM = T, alpha=0.5)
#' interpol_view(res, plotDEM = F, breakseq = seq(0,10,1), colNA="black")
#' 
#' }
#' @author Sebastian Gatscha
interpol_view <- function(res, plot=TRUE, breakseq, breakform = NULL, 
                          plotDEM=FALSE, fun = mean, ...) {
  # res <- viewshed(r = DEM_meter[[1]], shape=DEM_meter[[2]], turbine_locs = turbloc,  h1=1.8, h2=50)
  # fun = mean
  
  if (nrow(res$Result) > 1) {
    res$Result <- apply(res$Result, 2, function(d) {
      sum(d)
    })
  }
  
  visible = raster::rasterize(res$Raster_POI, res$DEM, field = res$Result, fun = fun)
  rasterpois <- cbind(res$Raster_POI, "z" = res$Result)
  
  if (plot) {
    pal <- colorRampPalette(c("green","orange","red"))
    maxR = max(rasterpois[,3])
    
    if (missing(breakseq)) {
      a = range(rasterpois[,3])
      breakseq <- seq(from = a[1], to = a[2], length.out = 5)
      
      if (!is.null(breakform)) {
        breakseq <- as.numeric(breakform(rasterpois[,3]))
      }
      breakseq <- breakseq[!duplicated(breakseq)]
    } 
    if (!any(breakseq == maxR)) {
      breakseq <- c(breakseq, maxR)
    }
    
    if (plotDEM) {
      raster::plot(res$DEM, legend = F)
      raster::plot(visible, breaks=breakseq, add = T, col=pal(length(breakseq)), ...)
      # raster::plot(visible, breaks=breakseq, add = T, col=pal(length(breakseq)), alpha=0.1)
    } else {
      raster::plot(visible, breaks=breakseq, col=pal(length(breakseq)), ...)
      # raster::plot(visible, breaks=breakseq, col=pal(length(breakseq)))
    }
    
    points(res$Turbines, pch=20, col="black", cex=1.5)
  }
  return(visible)
}


#' @title getISO3
#' @name getISO3
#' @description Get point values from the rworldmap package
#'
#' @export
#' 
#' @importFrom rworldmap getMap
#' @importFrom sp over
#' @importFrom sf st_coordinates st_as_sf st_transform
#' 
#' @param pp SpatialPoints or matrix
#' @param crs_pp The CRS of the points
#' @param col Which column/s should be returned
#' @param resol The search resolution if high accuracy is needed
#' @param coords The column names of the point matrix
#' @param ask A boolean, to ask which columns can be returned
#' 
#' @return A character vector
#' 
#' @examples \dontrun{
#' points = cbind(c(4488182.26267016, 4488852.91748256), 
#' c(2667398.93118627, 2667398.93118627))
#' getISO3(pp = points, ask = T)
#' getISO3(pp = points, crs_pp = 3035)
#' 
#' points <- as.data.frame(points)
#' colnames(points) <- c("x","y")
#' points <- st_as_sf(points, coords = c("x","y"))
#' st_crs(points) <- 3035
#' getISO3(pp = points, crs_pp = 3035)
#' }
#' @author Sebastian Gatscha
getISO3 <- function(pp, crs_pp = 4326, col = "ISO3", resol = "low", 
                    coords = c("LONG", "LAT"), ask=F) {
  # pp= points; col = "ISO3"; crs_pp = 3035; resol = "low"; coords = c("LONG", "LAT")
  # pp = points; col = "?"; crs_pp = 3035; resol = "low"; coords = c("LONG", "LAT"); ask=T
  
  if (col == "?") {ask=T}
  
  countriesSP <- rworldmap::getMap(resolution=resol)
  
  
  if (ask == TRUE) {
    print(sort(names(countriesSP)))
    col = readline(prompt="Enter an ISO3 code: ")
    # col = "afs"
    
    if (!col %in% sort(names(countriesSP))) {
      
      stop("Column not found")
    }
    
  }
  
  ## if sf
  if (class(pp)[1] %in% c("sf")) { 
    pp <- sf::st_coordinates(pp)
  }
  
  pp <- as.data.frame(pp)
  colnames(pp) <- coords
  
  pp <- st_as_sf(pp, coords=coords, crs = crs_pp)
  pp <- st_transform(pp, crs = countriesSP@proj4string@projargs)
  
  pp1 <- as(pp, "Spatial")
  
  # use 'over' to get indices of the Polygons object containing each point 
  worldmap_values <- sp::over(pp1, countriesSP)
  
  ##-------what if multiple columns?
  
  # return desired column of each country
  res <- as.character(unique(worldmap_values[[col]]))
  return(res)
}
# points=sample_POI
# getISO3(pp = points, ask = T)
# getISO3(pp = points, crs_pp = 3035)
# points=coordinates(sample_POI)
# dput(head(coordinates(sample_POI), 2))
# getISO3(points, crs_pp = 3035)
# points=st_as_sf(sample_POI)
# getISO3(points, crs_pp = 3035)


#' @title getDEM
#' @name getDEM
#' @description Get a DEM raster for a country based on ISO3 code
#'
#' @export
#' 
#' @importFrom raster getData projection crop extent crs projectRaster
#' @importFrom sp over
#' @importFrom sf st_coordinates st_as_sf st_transform
#' @importFrom methods as
#' 
#' @param ISO3 The ISO3 code of the country
#' @param clip boolean, indicating if polygon should be cropped.
#' Default is TRUE
#' @param polygon A Spatial / SimpleFeature Polygon to crop the DEM
#' 
#' @return A list with the DEM raster, and a SpatialPolygonsDataFrame or NULL
#' if no polygon is given
#' 
#' @examples \dontrun{
#' library(sp)
#' library(raster)
#' Polygon1 <- Polygon(rbind(c(4488182, 2667172), c(4488182, 2669343),
#'                           c(4499991, 2669343), c(4499991, 2667172)))
#' Polygon1 <- Polygons(list(Polygon1), 1);
#' Polygon1 <- SpatialPolygons(list(Polygon1))
#' Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
#' +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#' proj4string(Polygon1) <- CRS(Projection)
#' DEM_meter <- getDEM(Polygon1)
#' plot(DEM_meter[[1]])
#' plot(DEM_meter[[2]], add=T)
#' }
#' @author Sebastian Gatscha
getDEM <- function(polygon, ISO3 = "AUT", clip = TRUE) {
  # polygon = shape; ISO3 = "AUT"
  PROJ <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs"
  
  # DEM <- getData("SRTM", lon = st_bbox(polygon)[1], lat=st_bbox(polygon)[2])
  DEM <- raster::getData("alt", country=ISO3)
  
  if (clip) {
    ## if data.frame / sp object ? -----------------
    # shape <- st_as_sf(shape)
    if (class(polygon)[1] == "SpatialPolygonsDataFrame" | class(polygon)[1] == "SpatialPolygons" ) {
      polygon <- sf::st_as_sf(polygon)
    }
    shape <- sf::st_transform(polygon, crs = raster::projection(DEM))
    shape_SP <- as(shape, "Spatial")
    
    DEM <- raster::crop(x = DEM, raster::extent(shape_SP))
    # shape_meter <- sf::st_transform(shape, PROJ)
    shape_SP <- sp::spTransform(shape_SP, CRSobj = crs(PROJ))
  }

  DEM_meter <- raster::projectRaster(DEM, crs = PROJ)

  if (clip) {
    return(list(DEM_meter, shape_SP))
  } else {
    return(list(DEM_meter, NULL))
  }
}



