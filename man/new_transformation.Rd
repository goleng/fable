% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/transform.R
\name{new_transformation}
\alias{new_transformation}
\title{Create a new modelling transformation}
\usage{
new_transformation(transformation, inverse)
}
\arguments{
\item{transformation}{A function which transforms the data}

\item{inverse}{A function which is the inverse of a transformation}
}
\description{
Produces a new transformation for fable modelling functions which will be used to transform, back-transform, and adjust forecasts.
}
\details{
For more details about transformations, read the vignette:
\code{vignette("transformations", package = "fable")}
}
\examples{

scaled_logit <- function(x, lower=0, upper=1){
  log((x-lower)/(upper-x))
}
inv_scaled_logit <- function(x, lower=0, upper=1){
  (upper-lower)*exp(x)/(1+exp(x)) + lower
}
my_scaled_logit <- new_transformation(scaled_logit, inv_scaled_logit)

t_vals <- my_scaled_logit(1:10, 0, 100)
t_vals
invert_transformation(my_scaled_logit)(t_vals, 0, 100)

}
