
# Takes the model from the model_list and split it up into
# fixed effects and random effects
# Some users might want to mix models with an without random effects,
# and so we first try to seperate into fixed and random,
# and if no random effects are found for any of the models,
# we remove the column "random".
# Models without random effects will get NA in the random column.

extract_model_effects <- function(model_list) {
  # First we create a dataframe with the list of models
  mixed_effects = tibble::tibble("model" = as.character(model_list))

  suppressWarnings((
    # Then we use tidyr() to create a pipeline
    mixed_effects = mixed_effects %>%

      # First remove all whitespaces
      mutate(model = gsub("\\s", "", .$model)) %>%

      # Seperate model into dependent variable and predictors
      tidyr::separate(
        model,
        into = c("Dependent", "Predictors"),
        sep = "~"
      ) %>%

      # Then we separate the model by "("  - because: diagnosis + (1|subject)
      # The first part is placed in a column called "fixed"
      # the other part in a column called "random"
      # We use "extra = 'merge'" to only split into the 2 given parts
      # as it will elsewise split the string whenever "\\(" occurs
      tidyr::separate(
        Predictors,
        into = c("Fixed", "Random"),
        sep = "\\(",
        extra = "merge"
      ) %>%

      # Then we clean up those strings a bit
      # From fixed we remove the last "+"
      # From random we remove all "(" and ")"
      mutate(
        Fixed = gsub("[+]$", "", Fixed),
        Random = gsub('\\(|\\)', '', Random)

      )
  ))

  # If all models are without random effects,
  # drop column random
  if (all(is.na(mixed_effects$Random))) {
    mixed_effects$Random = NULL

  }

  return(mixed_effects)

}