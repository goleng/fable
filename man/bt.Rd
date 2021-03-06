% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hilo.R
\name{bt}
\alias{bt}
\title{Validate whether values fall in the hilo}
\usage{
bt(x, hilo)
}
\arguments{
\item{x}{A numeric vector of values.}

\item{hilo}{A vector of \code{hilo} objects.}
}
\description{
Validate whether values fall in the hilo
}
\examples{
myhilo <- new_hilo(lower = rnorm(10), upper = rnorm(10) + 5)
bt(0.2017, myhilo)

}
