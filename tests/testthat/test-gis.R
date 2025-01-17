test_that("testing prepInputs with deauthorized googledrive", {
  skip_on_cran()
  skip_if_not_installed("googledrive")

  if (interactive()) {
    testInitOut <- testInit(needGoogle = FALSE, "googledrive")
    on.exit({
      testOnExit(testInitOut)
    }, add = TRUE)

    testthat::with_mock(
      "reproducible::isInteractive" = function() {
        FALSE
      }, {
        noisyOutput <- capture.output({
          warn <- capture_warnings({
            BCR6_VT <- prepInputs(
              url = "https://drive.google.com/open?id=1sEiXKnAOCi-f1BF7b4kTg-6zFlGr0YOH",
              targetFile = "BCR6.shp",
              overwrite = TRUE
            )
          })
        })
      })
    expect_true(is(BCR6_VT, shapefileClassDefault()))

    NFDB_PT <- #Cache(
      prepInputs(
        url = "http://cwfis.cfs.nrcan.gc.ca/downloads/nfdb/fire_pnt/current_version/NFDB_point.zip",
        overwrite = TRUE,
        #targetFile = "NFDB_point_20181129.shp",
        #  alsoExtract = "similar",
        fun = "sf::st_read"
      )
    expect_is(NFDB_PT, "sf")
    expect_true(all(c("zip", "sbx", "shp", "xml", "shx", "sbn") %in%
                      fileExt(dir(pattern = "NFDB_point"))))

    noisyOutput <- capture.output({
      warn <- capture_warnings({
        NFDB_PT_BCR6 <- Cache(postProcess, NFDB_PT, studyArea = BCR6_VT)
      })
    })
    if (!all(grepl("attribute variables are assumed to be spatially constant", warn)))
      warnings(warn)
  }
})

test_that("testing rebuildColors", {
  testInitOut <- testInit(needGoogle = FALSE, "raster")
  on.exit({
    testOnExit(testInitOut)
  }, add = TRUE)

  x <- raster::raster(extent(0, 10, 0, 10), vals = runif(100, 0, 197))
  origColors <- list(origColors = character(0), origMinValue = 0, origMaxValue = 197.100006103516)
  expect_is(rebuildColors(x, origColors), "Raster")
})
