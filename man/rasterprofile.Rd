% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/visibility.R
\name{rasterprofile}
\alias{rasterprofile}
\title{rasterprofile}
\usage{
rasterprofile(r, xy1, xy2, plot = FALSE)
}
\arguments{
\item{r}{A DEM raster}

\item{xy1}{A matrix with X and Y coordinates for Point 1}

\item{xy2}{A matrix with X and Y coordinates for Points 2}

\item{plot}{Plot the process? Default is FALSE}
}
\value{
A boolean vector, indicating if Point 1 (xy1) is visible
from all elements of Points 2 (xy2)
}
\description{
Sample a raster along a straight line between 2 points
}
\author{
Sebastian Gatscha
}
