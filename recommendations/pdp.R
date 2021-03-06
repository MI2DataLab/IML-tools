library(gridExtra)
library(ggplot2)

library(DALEX)
library(flashlight)
library(iml)

data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., data = titanic_imputed,
                               classification = TRUE, probability = TRUE)

flashlight_predict <- function(X.model, new_data)
  predict(X.model, new_data)$predictions[,2]
iml_predict <- function(X.model, newdata)
  predict(X.model, newdata)$predictions[,2]

exp_dalex <- explain(ranger_model,
                     data = titanic_imputed,
                     y = titanic_imputed$survived,
                     label = "Ranger Model")
exp_flashlight <-flashlight(model = ranger_model,
                            data = titanic_imputed,
                            y = "survived",
                            label   = "Titanic Ranger",
                            metrics = list(auc = MetricsWeighted::AUC),
                            predict_function = flashlight_predict)
X <- titanic_imputed[
  which(names(titanic_imputed) != "survived")
  ]
exp_iml <-Predictor$new(ranger_model,
                        data = X,
                        y = titanic_imputed$survived,
                        predict.function = iml_predict)




### Partal Dependence Profile ###

# DALEX
pdp_dalex <- model_profile(exp_dalex,
                           variables = "fare",
                           type = "partial",
                           N = 1000,
                           grid_points = 101,
                           variable_splits_type = "uniform")
plot_dalex <- plot(pdp_dalex)

# flashlight
pdp_flashlight <- light_profile(exp_flashlight,
                                v = "fare",
                                type = "partial dependence",
                                pd_n_max = 1000,
                                n_bins = 101,
                                cut_type = "equal")
plot_flashlight <- plot(pdp_flashlight)

# iml 
pdp_iml <- FeatureEffect$new(exp_iml,
                             feature = "fare",
                             method = "pdp",
                             grid.size = 101)
plot_iml <- plot(pdp_iml)



p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_pdp.png", p, width = 4, height = 10)