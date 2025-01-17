% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/postProcess.R
\name{projectInputs}
\alias{projectInputs}
\alias{projectInputs.default}
\alias{projectInputs.Raster}
\alias{projectInputs.SpatVector}
\alias{projectInputs.SpatRaster}
\alias{projectInputs.sf}
\alias{projectInputs.Spatial}
\title{Project \verb{Raster*} or \verb{Spatial*} or \code{sf} objects}
\usage{
projectInputs(
  x,
  targetCRS,
  verbose = getOption("reproducible.verbose", 1),
  ...
)

\method{projectInputs}{default}(x, targetCRS, ...)

\method{projectInputs}{Raster}(
  x,
  targetCRS = NULL,
  verbose = getOption("reproducible.verbose", 1),
  rasterToMatch = NULL,
  cores = NULL,
  useGDAL = getOption("reproducible.useGDAL", FALSE),
  ...
)

\method{projectInputs}{SpatVector}(
  x,
  targetCRS,
  verbose = getOption("reproducible.verbose", 1),
  ...
)

\method{projectInputs}{SpatRaster}(
  x,
  targetCRS = NULL,
  verbose = getOption("reproducible.verbose", 1),
  rasterToMatch = NULL,
  cores = NULL,
  useGDAL = getOption("reproducible.useGDAL", FALSE),
  ...
)

\method{projectInputs}{sf}(
  x,
  targetCRS,
  verbose = getOption("reproducible.verbose", 1),
  ...
)

\method{projectInputs}{Spatial}(
  x,
  targetCRS,
  verbose = getOption("reproducible.verbose", 1),
  ...
)
}
\arguments{
\item{x}{A \verb{Raster*}, \verb{Spatial*} or \code{sf} object}

\item{targetCRS}{The CRS of x at the end  of this function (i.e., the goal)}

\item{verbose}{Numeric, -1 silent (where possible), 0 being very quiet,
1 showing more messaging, 2 being more messaging, etc.
Default is 1. Above 3 will output much more information about the internals of
Caching, which may help diagnose Caching challenges. Can set globally with an
option, e.g., \verb{options('reproducible.verbose' = 0) to reduce to minimal}}

\item{...}{Passed to \code{\link[raster:projectRaster]{raster::projectRaster()}}.}

\item{rasterToMatch}{Template \verb{Raster*} object passed to the \code{to} argument of
\code{\link[raster:projectRaster]{raster::projectRaster()}}, thus will changing the
resolution and projection of \code{x}.
See details in \code{\link[=postProcess]{postProcess()}}.}

\item{cores}{An \verb{integer*} or \code{'AUTO'}. This will be used if \code{gdalwarp} is
triggered. \verb{'AUTO'*} will calculate 90\% of the total
number of cores in the system, while an integer or rounded
float will be passed as the exact number of cores to be used.}

\item{useGDAL}{Logical or \code{"force"}. This is defunct; internals now can use
\code{terra} if \code{options("reproducible.useTerra" = TRUE)}, which is not (yet)
the default.}
}
\value{
A file of the same type as starting, but with projection (and possibly
other characteristics, including resolution, origin, extent if changed).

A GIS file (e.g., RasterLayer, SpatRaster etc.) that has been
appropriately reprojected.
}
\description{
A simple wrapper around the various different tools for these GIS types.
}
\examples{
library(sp)
library(raster)

# make a SpatialPolygon
coords1 <- structure(c(-123.98, -117.1, -80.2, -100, -123.98, 60.9, 67.73, 65.58, 51.79, 60.9),
                       .Dim = c(5L, 2L))
Sr1 <- Polygon(coords1)
Srs1 <- Polygons(list(Sr1), "s1")
shpEcozone <- SpatialPolygons(list(Srs1), 1L)
crs(shpEcozone) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

# make a "study area" that is subset of larger dataset
coords <- structure(c(-118.98, -116.1, -99.2, -106, -118.98, 59.9, 65.73, 63.58, 54.79, 59.9),
                      .Dim = c(5L, 2L))
Sr1 <- Polygon(coords)
Srs1 <- Polygons(list(Sr1), "s1")
StudyArea <- SpatialPolygons(list(Srs1), 1L)
crs(StudyArea) <- crs(shpEcozone)
projString <- "+proj=utm +zone=15 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
StudyArea <- sp::spTransform(StudyArea, CRSobj = projString)
projectInputs(shpEcozone, StudyArea)
}
\seealso{
\code{\link[=projectTo]{projectTo()}}
}
