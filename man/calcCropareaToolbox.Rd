% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calcCropareaToolbox.R
\name{calcCropareaToolbox}
\alias{calcCropareaToolbox}
\title{calcCropareaToolbox}
\usage{
calcCropareaToolbox(physical = TRUE, cells = "magpiecell")
}
\arguments{
\item{physical}{if TRUE the sum over all crops agrees with the cropland area per country
(not yet completly true, WIP)}

\item{cells}{Switch between "magpiecell" (59199) and "lpjcell" (67420)}
}
\value{
Magpie object with cropareas
}
\description{
This function uses the data from the LPJmL io Toolbox
to calculate cropareas in various formats.
!!This is still a WIP!!
}
\author{
David Hötten
}
