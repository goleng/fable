#' Fit a linear model with time series components
#' 
#' @param data A data frame
#' @param formula Model specification.
#' @param ... Additional arguments passed to lm
#' 
#' @export
#' 
#' @examples 
#' 
#' USAccDeaths %>% LM(log(value) ~ trend() + season())
LM <- function(data, formula, ...){
  # Capture user call
  cl <- call_standardise(match.call())
  
  # Coerce data
  data <- as_tsibble(data)
  
  # Handle multivariate inputs
  if(n_keys(data) > 1){
    return(multi_univariate(data, cl))
  }
  
  # Define specials
  specials <- new_specials_env(
    !!!lm_specials,
    .env = caller_env(),
    .vals = list(.data = data)
  )
  
  # Parse model
  model_inputs <- parse_model(data, formula)
  
  model_formula <- eval_tidy(model_inputs$model)
  if(is_formula(model_formula)){
    model_formula <- stats::as.formula(model_formula, specials)
  }
  else{
    model_formula <- new_formula(model_formula, 1, specials)
  }
  
  fit <- stats::lm(model_formula, data, ...)
  fit$call <- cl
  
  mable(
    key_vals = as.list(data)[key_vars(data)],
    data = (data %>%
              grouped_df(key_vars(.)) %>%
              nest)$data,
    model = list(enclass(fit, "LM",
                         !!!map(model_inputs[c("model", "response", "transformation")], eval_tidy)))
  )
}

#' @importFrom stats predict
#' @export
forecast.LM <- function(object, data, newdata = NULL, h=NULL, ...){
  if(is.null(newdata)){
    if(is.null(h)){
      h <- get_frequencies("all", data) %>%
        .[.>2] %>%
        min
    }
    future_idx <- data %>% pull(!!index(.)) %>% fc_idx(h)
    newdata <- tsibble(!!!set_names(list(future_idx), expr_text(index(data))), index = !!index(data))
  }

  # TODO: instead of replacing environment, just replace the data with newdata
  attr(object$terms, ".Environment") <- new_specials_env(
    !!!lm_specials,
    parent_env = child_env(caller_env(), .data = newdata)
  )
  
  fc <- predict(object, newdata, se.fit = TRUE)
  
  newdata %>%
    mutate(mean = biasadj(invert_transformation(object%@%"transformation"), fc$se.fit^2)(fc$fit),
           distribution = new_fcdist(qnorm, fc$fit, sd = fc$se.fit,
                                     transformation = invert_transformation(object%@%"transformation"),
                                     abbr = "N")
           )
}

#xreg is handled by lm
lm_specials <- list(
  trend = function(knots = NULL){
    origin <- min(.data[[expr_text(index(.data))]])
    trend(.data, knots, origin) %>% as.matrix
  },
  season = function(period = "smallest"){
    season(.data, period) %>% as_model_matrix
  },
  fourier = function(period = "smallest", K){
    origin <- min(.data[[expr_text(index(.data))]])
    fourier(.data, period, K, origin) %>% as.matrix
  }
)

#' @export
model_sum.LM <- function(x){
  "LM"
}

as_model_matrix <- function(tbl){
  stats::model.matrix(~ ., data = tbl)[,-1]
}