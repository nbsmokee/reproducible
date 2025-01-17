% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/postProcessTerra.R
\name{postProcessTerra}
\alias{postProcessTerra}
\alias{maskTo}
\alias{projectTo}
\alias{cropTo}
\alias{writeTo}
\title{Transform a GIS dataset so it has the properties (extent, projection, mask) of another}
\usage{
postProcessTerra(
  from,
  to,
  cropTo = NULL,
  projectTo = NULL,
  maskTo = NULL,
  writeTo = NULL,
  method = NULL,
  datatype = "FLT4S",
  overwrite = TRUE,
  ...
)

maskTo(
  from,
  maskTo,
  touches = FALSE,
  overwrite = FALSE,
  verbose = getOption("reproducible.verbose")
)

projectTo(from, projectTo, method, overwrite = FALSE)

cropTo(
  from,
  cropTo = NULL,
  needBuffer = TRUE,
  overwrite = FALSE,
  verbose = getOption("reproducible.verbose")
)

writeTo(
  from,
  writeTo,
  overwrite,
  isStack = FALSE,
  isBrick = FALSE,
  isRaster = FALSE,
  isSpatRaster = FALSE,
  datatype = "FLT4S"
)
}
\arguments{
\item{from}{A Gridded or Vector dataset on which to do one or more of:
crop, project, mask, and write}

\item{to}{A Gridded or Vector dataset which is the object
whose metadata will be the target for cropping, projecting, and masking of \code{from}.}

\item{cropTo}{Optional Gridded or Vector dataset which,
if supplied, will supply the extent with which to crop \code{from}. To omit
cropping completely, set this to \code{NA}. If supplied, this will override \code{to}
for the cropping step. Defaults to \code{NULL}, which means use \code{to}}

\item{projectTo}{Optional Gridded or Vector dataset, or \code{crs} object (e.g., sf::st_crs).
If Gridded it will supply
the \code{crs}, \code{extent}, \code{res}, and \code{origin}
to project the \code{from} to. If Vector, it will provide the \code{crs} only.
The resolution and extent will be taken from \code{res(from)} (i.e. \code{ncol(from)*nrow(from)}).
If a Vector, the extent of the \code{projectTo} is not used (unless it is also passed to \code{cropTo}.
To omit projecting, set this to \code{NA}.
If supplied, this will override \code{to}
for the projecting step. Defaults to \code{NULL}, which means use \code{to}}

\item{maskTo}{Optional Gridded or Vector dataset which,
if supplied, will supply the extent with which to mask \code{from}. If Gridded,
it will mask with the \code{NA} values on the \code{maskTo}; if Vector, it will
mask on the \code{terra::aggregate(maskTo)}. To omit
masking completely, set this to \code{NA}. If supplied,
this will override \code{to} for the masking step.
Defaults to \code{NULL}, which means use \code{to}}

\item{writeTo}{Optional character string of a filename to use \code{writeRaster} to save the final
object. Default is \code{NULL}, which means there is no \code{writeRaster}}

\item{method}{Used if \code{projectTo} is not \code{NULL}, and is the method used for
interpolation. See \code{terra::project}. Defaults to \code{"bilinear"}}

\item{datatype}{A character string, used if \code{writeTo} is not \code{NULL}. See \code{raster::writeRaster}}

\item{overwrite}{Logical. Used if \code{writeTo} is not \code{NULL}; also if \code{terra} determines
that the object requires writing to disk during a \code{crop}, \code{mask} or \code{project} call
e.g., because it is too large.}

\item{...}{Currently can be either \code{rasterToMatch}, \code{studyArea}, \code{filename2},
\code{useSAcrs}, or \code{targetCRS} to allow backwards
compatibility with \code{postProcess}. See section below for details.}

\item{touches}{See \code{terra::mask}}

\item{verbose}{Numeric, -1 silent (where possible), 0 being very quiet,
1 showing more messaging, 2 being more messaging, etc.
Default is 1. Above 3 will output much more information about the internals of
Caching, which may help diagnose Caching challenges. Can set globally with an
option, e.g., \verb{options('reproducible.verbose' = 0) to reduce to minimal}}

\item{needBuffer}{Logical. Defaults to \code{TRUE}, meaning nothing is done out
of the ordinary. If \code{TRUE}, then a buffer around the cropTo, so that if a reprojection
has to happen on the \code{cropTo} prior to using it as a crop layer, then a buffer
of 1.5 * res(cropTo) will occur prior, so that no edges are cut off.}

\item{isStack, isBrick, isRaster, isSpatRaster}{Logical. Default \code{FALSE}. Used to convert \code{from}
back to these classes prior to writing.}
}
\value{
An object of the same class as \code{from}, but potentially cropped (via \code{\link[=cropTo]{cropTo()}}),
projected (via \code{\link[=projectTo]{projectTo()}}), masked (via \code{\link[=maskTo]{maskTo()}}), and written to disk
(via \code{\link[=writeTo]{writeTo()}}).
}
\description{
This function provides a single step to achieve the GIS operations "crop", "project",
"mask" and possibly "write". This is intended to completely replace \code{\link[=postProcess]{postProcess()}}
(which primarily used GDAL, \code{Raster} and \code{sp}).
It uses primarily the \code{terra} package internally
(with some minor functions from \code{sf} and \code{raster})
in an attempt to be as efficient as possible.
For this function, Gridded means a \verb{Raster*} class object from \code{raster} or
a \code{SpatRaster} class object from \code{terra}.
Vector means a \verb{Spatial*} class object from \code{sp}, a \code{sf} class object
from \code{sf}, or a \code{SpatVector} class object from \code{terra}. This function is currently
part of the internals for some cases encountered by \code{\link[=postProcess]{postProcess()}}.
}
\section{Use Cases}{


The table below shows what will result from passing different classes to \code{from}
and \code{to}:

\tabular{lll}{
\code{from}\tab \code{to}\tab \code{from} will have:\cr
\code{Gridded}\tab \code{Gridded} \tab the extent, projection, origin, resolution and
masking where there are \code{NA} from the \code{to}\cr
\code{Gridded}\tab \code{Vector} \tab the projection, origin, and mask from \code{to}, and extent will
be a round number of pixels that fit within the extent
of \code{to}. Resolution will be the same as \code{from} \cr
\code{Vector}\tab \code{Vector} \tab the projection, origin, extent and mask from \code{to}\cr
}

If one or more of the \verb{*To} arguments are supplied, these will
override individual components of \code{to}. If \code{to} is omitted or \code{NULL},
then only the \verb{*To} arguments that are used will be performed. In all cases,
setting a \verb{*To} argument to \code{NA} will prevent that step from happening.
}

\section{Backwards compatibility with \code{postProcess}}{


\subsection{\code{rasterToMatch} and \code{studyArea}:}{

If these are supplied, \code{postProcessTerra} will use them instead
of \code{to}. If only \code{rasterToMatch} is supplied, it will be assigned to
\code{to}. If only \code{studyArea} is supplied, it will be used for \code{cropTo}
and \code{maskTo}; it will only be used for \code{projectTo} if \code{useSAcrs = TRUE}.
If both \code{rasterToMatch} and \code{studyArea} are supplied,
\code{studyArea} will only be applied to \code{maskTo} (and optionally \code{projectTo} if
\code{useSAcrs = TRUE}); everything else will be from \code{rasterToMatch}.
}

\subsection{\code{targetCRS}, \code{filename2}, \code{useSAcrs}:}{

\code{targetCRS} if supplied will be assigned to \code{projectTo}. \code{filename2} will
be assigned to \code{writeTo}. If \code{useSAcrs} is set, then the \code{studyArea}
will be assigned to \code{projectTo}. All of these will override any existing values
for these arguments.
}
}

\section{Cropping}{

If \code{cropTo} is not \code{NA}, postProcessTerra does cropping twice, both the first and last steps.
It does it first for speed, as cropping is a very fast algorithm. This will quickly remove
a bunch of pixels that are not necessary. But, to not create bias, this first crop is padded
by  \code{2 * res(from)[1]}), so that edge cells still have a complete set of neighbours.
The second crop is at the end, after projecting and masking. After the projection step,
the crop is no longer tight. Under some conditions, masking will effectively mask and crop in
one step, but under some conditions, this is not true, and the mask leaves padded NAs out to
the extent of the \code{from} (as it is after crop, project, mask). Thus the second
crop removes all NA cells so they are tight to the mask.
}

\seealso{
This function is meant to replace \code{\link[=postProcess]{postProcess()}} with the more efficient
and faster \code{terra} functions.
}
