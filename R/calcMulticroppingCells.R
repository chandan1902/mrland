#' @title calcMulticroppingCells
#'
#' @description Returns grid cells where multiple cropping takes place given the
#'              chosen scenario
#'
#' @param selectyears   Years to be returned
#' @param lpjml         LPJmL version required for respective inputs: natveg or crop
#' @param climatetype   Switch between different climate scenarios or
#'                      historical baseline "GSWP3-W5E5:historical"
#' @param scenario      "actual:total": currently multicropped areas calculated from total harvested areas
#'                                      and total physical areas per cell from readLanduseToolbox
#'                      "actual:crop" (crop-specific), "actual:irrigation" (irrigation-specific),
#'                      "actual:irrig_crop" (crop- and irrigation-specific) "total"
#'                      "potential:endogenous": potentially multicropped areas given
#'                                              temperature and productivity limits
#'                      "potential:exogenous": potentially multicropped areas given
#'                                             GAEZ suitability classification
#'
#' @return magpie object in cellular resolution
#' @author Felicitas Beier
#'
#' @examples
#' \dontrun{
#' calcOutput("MulticroppingCells", aggregate = FALSE)
#' }
#'
#' @importFrom madrat calcOutput readSource toolGetMapping
#' @importFrom magclass dimSums dimOrder
#'

calcMulticroppingCells <- function(selectyears, lpjml, climatetype, scenario) {

  # extract sub-scenario
  subscenario <- strsplit(scenario, split = ":")[[1]][2]
  scenario    <- strsplit(scenario, split = ":")[[1]][1]

  if (grepl("potential", scenario)) {

    # Cells that can potentially be multi-cropped (irrigation- and crop-specific)
    mcCells <- calcOutput("MulticroppingSuitability", selectyears = selectyears,
                          lpjml = "ggcmi_phase3_nchecks_9ca735cb",  ### ToDo: Switch to flexible lpjml argument (once LPJmL runs are ready)
                          climatetype = "GSWP3-W5E5:historical", ### ToDo: Switch to flexible climatetype argument (once LPJmL runs are ready)
                          minThreshold = 100, suitability = subscenario,
                          aggregate = FALSE)

  } else if (grepl(scenario, "actual")) {

    # Cells that are actually multi-cropped (ToDo: replace with calcFunction once ready)
    # (maybe with calcFunction it can even be crop-specific...)

    # areas where multicropping takes place currently (crop- and irrigation-specific)
    phys <- calcOutput("CropareaToolbox", physical = TRUE,
                       cells = "lpjcell", aggregate = FALSE)[, selectyears, ]
    harv <- calcOutput("CropareaToolbox", physical = FALSE,
                       cells = "lpjcell", aggregate = FALSE)[, selectyears, ]
    # keep for dimensionality
    phys[, , ] <- NA
    harv[, , ] <- NA

    if (grepl(subscenario, "total")) {

      # total actual multicropping area (some crop, irrigated or rainfed)
      tempPhys <- dimSums(readSource("LanduseToolbox", subtype = "physicalArea")[, selectyears, ],
                          dim = "irrigation")
      tempHarv <- dimSums(readSource("LanduseToolbox", subtype = "harvestedArea")[, selectyears, ],
                          dim = "irrigation")
      tempHarv <- dimSums(tempHarv[, , "pasture", invert = TRUE],
                          dim = "crop")

      # expand dimension
      phys[, , ] <- tempPhys
      harv[, , ] <- tempHarv

    } else if (grepl(subscenario, "irrig")) {

      # total actual multicropping area (some crop, irrigation-specific)
      tempPhys <- readSource("LanduseToolbox", subtype = "physicalArea")[, selectyears, ]
      tempHarv <- readSource("LanduseToolbox", subtype = "harvestedArea")[, selectyears, ]
      tempHarv <- dimSums(tempHarv[, , "pasture", invert = TRUE],
                          dim = "crop")

      # expand dimension
      phys[, , ] <- tempPhys
      harv[, , ] <- tempHarv

    } else if (grepl(subscenario, "crop")) {

      # areas where multicropping takes place currently (crop- and irrigation-specific)
      tempPhys <- dimSums(calcOutput("CropareaToolbox", physical = TRUE,
                                 cells = "lpjcell", aggregate = FALSE)[, selectyears, ],
                          dim = "irrigation")
      tempHarv <- dimSums(calcOutput("CropareaToolbox", physical = FALSE,
                                  cells = "lpjcell", aggregate = FALSE)[, selectyears, ],
                          dim = "irrigation")

      # expand dimension
      phys[, , ] <- tempPhys
      harv[, , ] <- tempHarv

    } else if (grepl(subscenario, "irrig_crop")) {

      # areas where multicropping takes place currently (crop- and irrigation-specific)
      phys <- calcOutput("CropareaToolbox", physical = TRUE, cells = "lpjcell",
                          aggregate = FALSE)[, selectyears, ]
      harv <- calcOutput("CropareaToolbox", physical = FALSE, cells = "lpjcell",
                          aggregate = FALSE)[, selectyears, ]

    } else {
      stop("Please select whether total, irrigation-specific (irrig), crop-specific (crop),
      or irrigation- and crop-specific (irrig_crop) currently multicropped areas shall be
      returned through extension of scenario argument separated by :")
    }

    # crop aggregation
    map <- toolGetMapping("MAgPIE_LPJmL.csv",
      type = "sectoral",
      where = "mappingfolder"
    ) # ToDo: when calc function is ready: select required crop-type through argument before

    harv <- toolAggregate(harv, map,
                             from = "MAgPIE", to = "LPJmL",
                             dim = 3.2, partrel = TRUE)
    harv <- dimOrder(harv, c(1, 2), dim = 3)
    phys <- toolAggregate(phys, map,
                          from = "MAgPIE", to = "LPJmL",
                          dim = 3.2, partrel = TRUE)
    phys <- dimOrder(phys, c(1, 2), dim = 3)

    # cropping intensity factor
    currMC <- ifelse(phys > 0, harv / phys, NA)

    # boolean of multicropped areas
    mcCells <- currMC
    mcCells[is.na(currMC)] <- 0
    mcCells[currMC <= 1]   <- 0
    mcCells[currMC > 1]    <- 1

  } else {
    stop("Chosen scenario in calcMulticroppingCells not available:
         Please select potential for grid cells that can be potentially multi-cropped,
         or actual for gird cells that are currently multi-cropped,
         and sub-specification (for actual: total, crop, irrig, cropIrrig,
         for potential: endogenous, exogenous) separated by :")
  }

  ##############
  ### Checks ###
  ##############

  if (any(is.na(mcCells))) {
    stop("calcMulticroppingCells produced NA values")
  }
  if (any(mcCells != 1 & mcCells != 0)) {
    stop("Problem in calcMulticroppingCells: Value should be 0 or 1!")
  }

  ##############
  ### Return ###
  ##############
  out         <- mcCells
  unit        <- "boolean"
  description <- "Multicropping of different crops under
                  irrigated and rainfed conditions respectively.
                  1 = multi-cropped, 0 = not multi-cropped"

  return(list(x            = out,
              weight       = NULL,
              unit         = unit,
              description  = description,
              isocountries = FALSE))
}
