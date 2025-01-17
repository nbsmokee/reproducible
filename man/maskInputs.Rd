% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/postProcess.R
\name{maskInputs}
\alias{maskInputs}
\alias{maskInputs.Raster}
\alias{maskInputs.Spatial}
\alias{maskInputs.SpatVector}
\alias{maskInputs.SpatRaster}
\alias{maskInputs.sf}
\title{Mask module inputs}
\usage{
maskInputs(x, studyArea, ...)

\method{maskInputs}{Raster}(
  x,
  studyArea,
  rasterToMatch = NULL,
  maskWithRTM = NULL,
  verbose = getOption("reproducible.verbose", 1),
  ...
)

\method{maskInputs}{Spatial}(
  x,
  studyArea,
  rasterToMatch = NULL,
  maskWithRTM = FALSE,
  verbose = getOption("reproducible.verbose", 1),
  useCache = getOption("reproducible.useCache", FALSE),
  ...
)

\method{maskInputs}{SpatVector}(
  x,
  studyArea,
  rasterToMatch = NULL,
  maskWithRTM = FALSE,
  verbose = getOption("reproducible.verbose", 1),
  useCache = getOption("reproducible.useCache", FALSE),
  ...
)

\method{maskInputs}{SpatRaster}(
  x,
  studyArea,
  rasterToMatch = NULL,
  maskWithRTM = FALSE,
  verbose = getOption("reproducible.verbose", 1),
  useCache = getOption("reproducible.useCache", FALSE),
  ...
)

\method{maskInputs}{sf}(
  x,
  studyArea,
  verbose = getOption("reproducible.verbose", 1),
  useCache = getOption("reproducible.useCache", FALSE),
  ...
)
}
\arguments{
\item{x}{An object to do a geographic raster::mask/raster::intersect.
See methods.}

\item{studyArea}{\verb{SpatialPolygons*} object used for masking and possibly cropping
if no \code{rasterToMatch} is provided.
If not in same CRS, then it will be \code{spTransform}ed to
CRS of \code{x} before masking. Currently, this function will not reproject the
\code{x}. Optional in \code{postProcess}.}

\item{...}{Passed to methods. None currently implemented.}

\item{rasterToMatch}{Template \verb{Raster*} object used for cropping (so extent should be
the extent of desired outcome) and reprojecting (including changing the
resolution and projection).
See details in \code{\link[=postProcess]{postProcess()}}.}

\item{maskWithRTM}{Logical. If \code{TRUE}, then the default,}

\item{verbose}{Numeric, -1 silent (where possible), 0 being very quiet,
1 showing more messaging, 2 being more messaging, etc.
Default is 1. Above 3 will output much more information about the internals of
Caching, which may help diagnose Caching challenges. Can set globally with an
option, e.g., \verb{options('reproducible.verbose' = 0) to reduce to minimal}}

\item{useCache}{Logical, default \code{getOption("reproducible.useCache", FALSE)}, whether
\code{Cache} is used internally.}
}
\value{
A GIS file (e.g., RasterLayer, SpatRaster etc.) that has been
appropriately masked.
}
\description{
This function can be used to mask inputs from data. Masking here is
equivalent to \code{raster::mask} (though \code{\link[=fastMask]{fastMask()}} is used here)
or \code{raster::intersect}.
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
maskInputs(shpEcozone, StudyArea)

}
\seealso{
\code{\link[=maskTo]{maskTo()}}, \code{\link[=postProcess]{postProcess()}} for related examples
}
\author{
Eliot McIntire and Jean Marchal
}
