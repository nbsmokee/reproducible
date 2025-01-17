################################################################################
#' Create reproducible digests of objects in R
#'
#' Not all aspects of R objects are captured by current hashing tools in R
#' (e.g. `digest::digest`, `knitr` caching, `archivist::cache`).
#' This is mostly because many objects have "transient"
#' (e.g., functions have environments), or "disk-backed" features.
#' Since the goal of using reproducibility is to have tools that are not session specific,
#' this function attempts to strip all session specific information so that the digest
#' works between sessions and operating systems.
#' It is tested under many conditions and object types, there are bound to be others that don't
#' work correctly.
#'
#' @section Classes:
#'
#' `Raster*` objects have the potential for disk-backed storage, thus, require more work.
#' Also, because `Raster*` can have a built-in representation for having their data content
#' located on disk, this format will be maintained if the raster already is file-backed,
#' i.e., to create `.tif` or `.grd` backed rasters, use `writeRaster` first,
#' then `Cache`.
#' The \file{.tif} or \file{.grd} will be copied to the \file{raster/} subdirectory of the
#' `cachePath`.
#' Their RAM representation (as an R object) will still be in the usual  \file{cacheOutputs/}
#' (or formerly \file{gallery/}) directory.
#' For `inMemory` raster objects, they will remain as binary `.RData` files.
#'
#' Functions (which are contained within environments) are
#' converted to a text representation via a call to `format(FUN)`.
#'
#' Objects contained within a list or environment are recursively hashed
#' using [digest::digest()], while removing all references to
#' environments.
#'
#' Character strings are first assessed with `dir.exists` and `file.exists`
#' to check for paths. If they are found to be paths, then the path is hashed with
#' only its filename via `basename(filename)`. If it is actually a path, we suggest
#' using `asPath(thePath)`
#'
#' @param object an object to digest.
#'
#' @param objects Optional character vector indicating which objects are to
#'                be considered while making digestible. This argument is not used
#'                in the default cases; the only known method that uses this
#'                in the default cases; the only known method that uses this
#'                argument is the `simList` class from `SpaDES.core`.
#'
#' @inheritParams Cache
#'
#' @return A hash i.e., digest of the object passed in.
#'
#' @author Eliot McIntire
#' @export
#' @importFrom digest digest
#' @keywords internal
#' @rdname robustDigest
#' @examples
#'
#' a <- 2
#' tmpfile1 <- tempfile()
#' tmpfile2 <- tempfile()
#' save(a, file = tmpfile1)
#' save(a, file = tmpfile2)
#'
#' # treats as character string, so 2 filenames are different
#' digest::digest(tmpfile1)
#' digest::digest(tmpfile2)
#'
#' # tests to see whether character string is representing a file
#' .robustDigest(tmpfile1)
#' .robustDigest(tmpfile2) # same
#'
#' # if you tell it that it is a path, then you can decide if you want it to be
#' #  treated as a character string or as a file path
#' .robustDigest(asPath(tmpfile1), quick = TRUE)
#' .robustDigest(asPath(tmpfile2), quick = TRUE) # different because using file info
#'
#' .robustDigest(asPath(tmpfile1), quick = FALSE)
#' .robustDigest(asPath(tmpfile2), quick = FALSE) # same because using file content
#'
#' # Rasters are interesting because it is not know a priori if it
#' #   it has a file name associated with it.
#' library(raster)
#' r <- raster(extent(0,10,0,10), vals = 1:100)
#'
#' # write to disk
#' r1 <- writeRaster(r, file = tmpfile1)
#' r2 <- writeRaster(r, file = tmpfile2)
#'
#' digest::digest(r1)
#' digest::digest(r2) # different
#' digest::digest(r1)
#' digest::digest(r2) # different
#' .robustDigest(r1)
#' .robustDigest(r2) # same... data are the same in the file
#'
#' # note, this is not true for comparing memory and file-backed rasters
#' .robustDigest(r)
#' .robustDigest(r1) # different
#'
setGeneric(".robustDigest", function(object, .objects = NULL,
                                     length = getOption("reproducible.length", Inf),
                                     algo = "xxhash64",
                                     quick = getOption("reproducible.quick", FALSE),
                                     classOptions = list(), ...) {
  standardGeneric(".robustDigest")
})

#' @rdname robustDigest
#' @importFrom rlang eval_tidy
#' @export
setMethod(
  ".robustDigest",
  signature = "ANY",
  definition = function(object, .objects, length, algo, quick,
                        classOptions) {
    # browser(expr = exists("._robustDigest_1"))
    if (is(object, "quosure")) {# can't get this class from rlang via importClass rlang quosure
      object <- eval_tidy(object)
    }

    if (is(object, "cluster")) {# can't get this class from rlang via importClass rlang quosure
      out <- .doDigest(NULL, algo)
      return(out)
    }

    if (inherits(object, "SpatRaster")) {
      if (!requireNamespace("terra", quietly = TRUE) && getOption("reproducible.useTerra", FALSE))
        stop("Please install terra package")
      if (any(nchar(terra::sources(object)) > 0)) {
        out <- lapply(terra::sources(object), function(x) {
          if (grepl("^NETCDF:", x)) {
            x <- sub("^NETCDF:\"", "", x)
            x <- sub("\":.*$", "", x)
          }
          digest(file = x, length = length, algo = algo)
        })
        dig <- .robustDigest(append(
          list(terra::nrow(object), terra::ncol(object), terra::nlyr(object),
               terra::res(object), terra::crs(object),
               terra::ext(object)), names(object), ),
          length = length, quick = quick,
          algo = algo, classOptions = classOptions) # don't include object@data -- these are volatile
        out <- .doDigest(list(out, dig), algo = algo)
      } else {
        out <- .doDigest(terra::wrap(object), algo)
      }

      return(out)
    }

    if (any(inherits(object, "SpatVector"), inherits(object, "SpatRaster"))) {
      if (!requireNamespace("terra", quietly = TRUE) && getOption("reproducible.useTerra", FALSE))
        stop("Please install terra package")
      out <- .doDigest(terra::wrap(object), algo)
      return(out)
    }

    # passByReference -- while doing pass by reference attribute setting is faster, is
    #   may be wrong. This caused issue #115 -- now fixed because it doesn't do pass by reference
    object1 <- .removeCacheAtts(object)
    .doDigest(object1, algo)
})

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "function",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    .robustDigestFormatOnly(object, algo = algo)
})

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "expression",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    .robustDigestFormatOnly(object, algo = algo)
})

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "language",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    .robustDigestFormatOnly(object, algo = algo)
  })

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "character",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    object <- .removeCacheAtts(object)

    simpleDigest <- TRUE
    if (!quick) {
      if (any(unlist(lapply(object[1:10], file.exists)))) { # only try first 10 elements
        simpleDigest <- FALSE
      }}
    if (!simpleDigest) {
      # browser(expr = exists("hhhh"))
      unlist(lapply(object, function(x) {
        # browser(expr = exists("hhhh"))
        if (dir.exists(x)) {
          .doDigest(basename(x), algo)
        } else if (file.exists(x)) {
          digest(file = x, length = length, algo = algo)
        } else {
          .doDigest(x, algo)
        }
      }))
      #} else {
      #.doDigest(object, algo = algo)
      #}
    } else {
      .doDigest(object, algo = algo)
    }
  })

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "Path",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    nParentDirs <- attr(object, "nParentDirs")
    object <- .removeCacheAtts(object)

    if (!quick) {
      lapply(object, function(x) {
        isExistentFile <- FALSE
        if (file.exists(x)) {
          if (!dir.exists(x)) {
            isExistentFile <- TRUE
          }
        }
        if (isExistentFile) {
          digest::digest(file = x, length = length, algo = algo)
        } else {
          # just do file basename as a character string, if file does not exist
          .doDigest(.basenames(x, nParentDirs), algo = algo)
        }
      })
    } else {
      .doDigest(.basenames(object, nParentDirs), algo = algo)
    }
})

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "environment",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    object <- .removeCacheAtts(object)
    if (is.null(classOptions[["prevEnvir"]])) {
      classOptions[["prevEnvir"]] <- list()
      doneAlready <- list(FALSE)
    } else {
      doneAlready <- lapply(classOptions[["prevEnvir"]], function(pe) identical(pe, object))
    }
    classOptions[["prevEnvir"]] <- unique(append(classOptions[["prevEnvir"]], object))

    if (!any(unlist(doneAlready))) {
      asList <- as.list(object, all.names = TRUE)
      da <- which(unlist(doneAlready))
      if (length(da))
        asList <- asList[-da]
      rd <- .robustDigest(asList, .objects = .objects,
                          length = length,
                          algo = algo, quick = quick, classOptions = classOptions)
    } else {
      rd <- NULL
    }
    return(rd)
  })

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "list",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    object <- .removeCacheAtts(object)
    # browser(expr = exists("._robustDigest_2"))
    if (!is.null(.objects)) object <- object[.objects]
    lapply(.sortDotsUnderscoreFirst(object), function(x) {
      .robustDigest(object = x, .objects = .objects,
                    length = length,
                    algo = algo, quick = quick, classOptions = classOptions)
    })
  })

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "data.frame",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    #  Need a specific method for data.frame or else it get "list" method, which is wrong
    object <- .removeCacheAtts(object)
    dig <- lapply(object, .robustDigest, algo = algo, quick = quick, classOptions = classOptions)
    .robustDigest(unlist(dig), quick = TRUE, algo = algo, classOptions = classOptions)
})


#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "numeric",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    #  Need a specific method for data.frame or else it get "list" method, which is wrong
    object <- .removeCacheAtts(object)
    # From ad hoc tests, 6 was the highest I could go to maintain consistent between Linux and Windows
    .doDigest(round(object, getOption("reproducible.digestDigits", 7)), algo = algo)
  })

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "matrix",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    #  Need a specific method for data.frame or else it get "list" method, which is wrong
    object <- .removeCacheAtts(object)
    dim(object) <- NULL
    .robustDigest(object, classOptions = classOptions)
    # From ad hoc tests, 6 was the highest I could go to maintain consistent between Linux and Windows
  })

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "integer",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    #  Need a specific method for data.frame or else it get "list" method, which is wrong
    object <- .removeCacheAtts(object)
    # From ad hoc tests, 7 was the highest I could go to maintain consistent between Linux and Windows
    .doDigest(object, algo = algo)
  })

#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "Raster",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    object <- .removeCacheAtts(object)

    if (getOption("reproducible.useNewDigestAlgorithm") < 2)  {
      if (is(object, "RasterStack")) {
        # have to do one file at a time with Stack
        dig <- suppressWarnings(
          lapply(object@layers, function(yy) {
            .digestRasterLayer(yy, length = length, algo = algo, quick = quick)
          })
        )
      } else {
        # Brick and Layers have only one file
        dig <- suppressWarnings(
          .digestRasterLayer(object, length = length, algo = algo, quick = quick))
      }
    } else {
      dig <- suppressWarnings(
        .digestRasterLayer(object, length = length, algo = algo, quick = quick))
    }
    dig <- .doDigest(unlist(dig))
    return(dig)
})


#' @rdname robustDigest
#' @export
setMethod(
  ".robustDigest",
  signature = "Spatial",
  definition = function(object, .objects, length, algo, quick, classOptions) {
    object <- .removeCacheAtts(object, passByReference = FALSE)

  if (is(object, "SpatialPoints")) {
      aaa <- as.data.frame(object)
    } else {
      aaa <- object
    }

    # The following Rounding is necessary to make digest equal on linux and windows
    if (inherits(aaa, "SpatialPolygonsDataFrame")) {
      bbb <- unlist(lapply(as.data.frame(aaa), is.numeric))
      if (sum(bbb)) {
        bbbWh <- which(bbb)
        for (i in bbbWh) { # changed because may not have correct names, can be NAs, Eliot March 2019
                           #  Error was: Error in round(aaa[[i]], 4) :
                           # non-numeric argument to mathematical function
          aaa[[i]] <- round(aaa[[i]], 4)
        }
      }
    }

    #
    .doDigest(aaa, algo = algo)
})

.basenames <- function(object, nParentDirs) {
  if (missing(nParentDirs)) {
    nParentDirs <- 0
  }
  object <- if (nParentDirs > 0) {
    obj <- object
    objOut <- basename(obj)
    for (i in seq_len(nParentDirs)) {
      obj <- dirname(obj)
      objOut <- file.path(basename(obj), objOut)
    }
    objOut
  } else {
    basename(object)
  }
  object
}

#' Remove attributes that are highly varying
#'
#' @importFrom data.table setattr
#' @param x Any arbitrary R object that could have attributes
#' @param passByReference Logical. If `TRUE`, the default, this uses `data.table::setattr`
#'   to remove several attributes that are unnecessary for digesting, specifically `tags`,
#'   `.Cache` and `call`
.removeCacheAtts <- function(x, passByReference = FALSE) {
  if (passByReference) {
    setattr(x, "tags", NULL)
    setattr(x, ".Cache", NULL)
    setattr(x, "call", NULL)
  } else {
    if (!is.null(attr(x, "tags")))
      attr(x, "tags") <- NULL
    if (!is.null(attr(x, ".Cache")))
      attr(x, ".Cache") <- NULL
    if (!is.null(attr(x, "call")))
      attr(x, "call") <- NULL
  }
  x
}

.robustDigestFormatOnly <- function(object, .objects, length, algo, quick,
                               classOptions) {
  object <- .removeCacheAtts(object)
  .doDigest(format(object), algo = algo)
}

.doDigest <- function(x, algo, length = Inf, file,
                      newAlgo = getOption("reproducible.useNewDigestAlgorithm"),
                      cacheSpeed = getOption("reproducible.cacheSpeed", "slow")) {
  if (missing(algo)) algo = formals(.robustDigest)$algo

  out <- if (!missing(file)) {
    digest::digest(file = x, algo = algo, length = length)
  } else {
    if (isTRUE(newAlgo > 0)) {
      if (cacheSpeed == "fast") {
        cacheSpeed <- 2L
      } else if (cacheSpeed == "slow") {
        cacheSpeed <- 1L
      }
    } else {
      cacheSpeed <- 2L
    }
    out <- if (cacheSpeed == 1) {
      digest(x, algo = algo)
    } else if (cacheSpeed == 2) {
      if (!requireNamespace("fastdigest", quietly = TRUE))
        stop(requireNamespaceMsg("fastdigest", "to use options('reproducible.useNewDigestAlgorithm' = FALSE"))
      fastdigest::fastdigest(x)
    } else {
      stop("options('reproducible.cacheSpeed') must be 1, 2, 'slow' or 'fast'")
    }
    out
  }
  out
}
