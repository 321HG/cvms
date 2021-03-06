# plot functions

#' @title Density plot for a metric
#' @description
#'  \Sexpr[results=rd, stage=render]{lifecycle::badge("experimental")}
#'
#'  Creates a \code{\link[ggplot2:ggplot]{ggplot2}} object with a density plot
#'  for one of the columns in the passed \code{data.frame}(s).
#'
#'  Note: In its current form, it is mainly intended as a quick way to visualize
#'  the results from cross-validations and baselines (random evaluations).
#'  It may change significantly in future versions.
#' @author Ludvig Renbo Olsen, \email{r-pkgs@@ludvigolsen.dk}
#' @export
#' @family plotting functions
#' @param results \code{data.frame} with a metric column to create density plot for.
#'
#'  To only plot the baseline, set to \code{NULL}.
#' @param baseline \code{data.frame} with the random evaluations from \code{\link[cvms:baseline]{baseline()}}.
#'  Should contain a column for the \code{metric}.
#'
#'  To only plot the results, set to \code{NULL}.
#' @param metric Name of the metric column in \code{`results`} to plot. (Character)
#' @param fill Colors of the plotted distributions.
#'  The first color is for the \code{`baseline`}, the second for the \code{`results`}.
#' @param alpha Transparency of the distribution (\code{0 - 1}).
#' @param xlim Limits for the x-axis. Can be set to \code{NULL}.
#'
#'  E.g. \code{c(0, 1)}.
#' @param theme_fn The \code{ggplot2} theme function to apply.
#' @return
#'  A \code{ggplot2} object with the density of a metric, possibly split
#'  in \emph{`Results`} and \emph{`Baseline`}.
#' @examples
#' \donttest{
#' # Attach packages
#' library(cvms)
#' library(dplyr)
#'
#' # We will use the musicians and predicted.musicians datasets
#' musicians
#' predicted.musicians
#'
#' # Set seed
#' set.seed(42)
#'
#' # Create baseline for targets
#' bsl <- baseline_multinomial(
#'   test_data = musicians,
#'   dependent_col = "Class",
#'   n = 20  # Normally 100
#' )
#'
#' # Evaluate predictions grouped by classifier and fold column
#' eval <- predicted.musicians %>%
#'   dplyr::group_by(Classifier, `Fold Column`) %>%
#'   evaluate(
#'   target_col = "Target",
#'   prediction_cols = c("A", "B", "C", "D"),
#'   type = "multinomial"
#' )
#'
#' # Plot density of the Overall Accuracy metric
#' plot_metric_density(
#'   results = eval,
#'   baseline = bsl$random_evaluations,
#'   metric = "Overall Accuracy",
#'   xlim = c(0,1)
#' )
#'
#' # The bulk of classifier results are much better than
#' # the baseline results
#' }
plot_metric_density <- function(results = NULL,
                                baseline = NULL,
                                metric = "",
                                fill = c("darkblue", "lightblue"),
                                alpha = 0.6,
                                theme_fn = ggplot2::theme_minimal,
                                xlim = NULL) {

  # Check arguments ####
  assert_collection <- checkmate::makeAssertCollection()
  if (is.null(results) && is.null(baseline)){
    assert_collection$push(
      "Either 'results' or 'baseline' must be a data frame. Both were 'NULL'.")
  }
  checkmate::assert_data_frame(x = results, col.names = "unique", null.ok = TRUE,
                               add = assert_collection)
  checkmate::assert_data_frame(x = baseline, col.names = "unique", null.ok = TRUE,
                               add = assert_collection)
  checkmate::assert_string(x = metric, min.chars = 1,
                           add = assert_collection)
  checkmate::assert_character(x = fill, null.ok = TRUE, # TODO test NULL works?
                           add = assert_collection)
  checkmate::assert_number(x = alpha, lower = 0, upper = 1,
                           add = assert_collection)
  checkmate::assert_function(x = theme_fn,
                             add = assert_collection)
  checkmate::assert_numeric(x = xlim, null.ok = TRUE,
                            add = assert_collection)
  checkmate::reportAssertions(assert_collection)
  if (!is.null(results))
    checkmate::assert_names(x = names(results), must.include = metric,
                            add = assert_collection)
  if (!is.null(baseline))
    checkmate::assert_names(x = names(baseline), must.include = metric,
                            add = assert_collection)
  checkmate::reportAssertions(assert_collection)
  # End of argument checks ####

  # Simplify results
  if (!is.null(results)){
    results <- results %>%
      base_select(cols = metric) %>%
      dplyr::mutate(dataset = "Results")
  }

  # Simplify baseline
  if (!is.null(baseline)) {
    baseline <- baseline %>%
      base_select(cols = metric) %>%
      dplyr::mutate(dataset = "Baseline")
  } else {
    fill <- fill[[2]]
  }

  # Combine results and baseline
  # It should work when one of them is NULL
  data_to_plot <- results %>%
    dplyr::bind_rows(baseline)

  # TODO Check when metric col contains NAs?

  # Add ` ` around the metric name
  # if it's not already there
  if (substr(metric, 1, 1) != "`") {
    metric <- paste0("`", metric, "`")
  }

  # Create and return a density plot
  data_to_plot %>%
    ggplot2::ggplot(ggplot2::aes_string(x = metric, fill = "dataset")) +
    ggplot2::geom_density(alpha = alpha) +
    ggplot2::scale_fill_manual(values = fill) +
    ggplot2::coord_cartesian(xlim = xlim) +
    theme_fn() +
    ggplot2::labs(y = "Density") +
    ggplot2::theme(
      # Add margin to axis labels
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(0, 6, 0, 0)),
      axis.title.x.bottom = ggplot2::element_text(margin = ggplot2::margin(6, 0, 0, 0))
    )
}
