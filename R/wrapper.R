#' @importFrom tibble new_tibble
#' @importFrom dplyr grouped_df
wrap_ts_model <- function(modelfn, data, model, response, transformation, args, period = "all", cl = "Call information lost", ...){
  period <- get_frequencies(period, data)

  # Fit model
  fit <- eval_tidy(call2(modelfn, expr(msts(!!model_lhs(model), !!period)), !!!args, !!!dots_list(...)), data = data)

  # Backtransform
  fit$fitted <- invert_transformation(transformation)(fit$fitted)
  fit$x <- invert_transformation(transformation)(fit$x)
  
  # Fix components
  fit$call <- cl
  fit$series <- expr_text(model_lhs(model))
  # Output model
  mable(
    key_vals = as.list(data)[key_vars(data)],
    data = (data %>%
      grouped_df(key_vars(.)) %>%
      nest)$data,
    model = list(enclass(fit, "ts_model",
                         model = model, response = response,
                         transformation = transformation))
  )
}

#' @importFrom forecast forecast
#' @importFrom purrr map2
#' @importFrom stats qnorm time 
#' @importFrom utils tail
#' @importFrom dplyr pull
#' @export
forecast.ts_model <- function(object, data, bootstrap = FALSE, ...){
  if(bootstrap){
    abort("Bootstrap forecast intervals not yet supported for this model")
  }
  class(object) <- class(object)[-match("ts_model", class(object))]
  fc <- forecast(object, ...)
  # Assume normality
  se <- (fc$upper[,1] - fc$lower[,1])/qnorm(0.5 * (1 + fc$level[1] / 100))/2
  future_idx <- data %>% pull(!!index(.)) %>% fc_idx(length(fc$mean))
  tsibble(!!index(data) := future_idx,
          mean = biasadj(invert_transformation(object%@%"transformation"), se^2)(fc$mean), 
          distribution = new_fcdist(qnorm, fc$mean, sd = se, transformation = invert_transformation(object%@%"transformation"), abbr = "N"),
          index = !!index(data))
}

#' @export
model_sum.ts_model <- function(x){
  NextMethod()
}