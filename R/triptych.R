# Bayesian triptych plot
# By TJ Mahr
# https://www.tjmahr.com/bayes-theorem-in-three-panels/

build_triptych_panels <- function() {
  suppressPackageStartupMessages(library(brms))
  suppressPackageStartupMessages(library(tidybayes))

  options(mc.cores = parallel::detectCores(),
          brms.backend = "cmdstanr")

  data <- tibble(
    age = c(38, 45, 52, 61, 80, 74),
    prop = c(0.146, 0.241, 0.571, 0.745, 0.843, 0.738)
  )

  inv_logit <- function(x) 1 / (1 + exp(-x))

  theme_triptych <- function(title_color) {
    theme_bw(base_family = "Raleway", base_size = 16) +
      theme(panel.grid = element_blank(),
            axis.text = element_blank(),
            axis.ticks = element_blank(),
            axis.title = element_blank(),
            plot.title = element_text(face = "bold", color = title_color, hjust = 0.5),
            plot.subtitle = element_text(color = "grey50", hjust = 0.5))
  }

  model_formula <- bf(
    # Logistic curve
    prop ~ inv_logit(asymlogit) * inv(1 + exp((mid - age) * exp(scale))),
    # Each term in the logistic equation gets a linear model
    asymlogit ~ 1,
    mid ~ 1,
    scale ~ 1,
    # Precision
    phi ~ 1,
    # This is a nonlinear Beta regression model
    nl = TRUE,
    family = Beta(link = identity)
  )

  prior_fixef <- c(
    # Point of steepest growth is age 4 plus/minus 2 years
    prior(normal(48, 12), nlpar = "mid", coef = "Intercept"),
    prior(normal(1.25, .75), nlpar = "asymlogit", coef = "Intercept"),
    prior(normal(-2, 1), nlpar = "scale", coef = "Intercept")
  )

  prior_phi <- c(
    prior(normal(2, 1), dpar = "phi", class = "Intercept")
  )

  fit_prior <- brm(
    model_formula,
    data = data,
    prior = c(prior_fixef, prior_phi),
    iter = 2000,
    chains = 4,
    seed = 12345,
    sample_prior = "only",
    control = list(adapt_delta = 0.9, max_treedepth = 15)
  )

  draws_prior <- data %>%
    expand(age = 0:100) %>%
    add_epred_draws(fit_prior, ndraws = 100)

  p1 <- ggplot(draws_prior) +
    aes(x = age, y = .epred) +
    geom_line(aes(group = .draw), alpha = .2) +
    theme(
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank()
    ) +
    expand_limits(y = 0:1) +
    labs(title = "The Prior", subtitle = "Plausible curves before seeing the data") +
    theme_triptych(title_color = "#931e18")


  # Maximum likelihood estimate
  fm1 <- nls(prop ~ SSlogis(age, Asym, xmid, scal), data)
  new_data <- tibble(age = 0:100) %>%
    mutate(fit = predict(fm1, newdata = .))

  p2 <- ggplot(data) +
    aes(x = age, y = prop) +
    geom_line(aes(y = fit), data = new_data, size = 1, color = "#20235b") +
    geom_point(fill = "#247d3f", color = "white", size = 4, pch = 21) +
    theme(
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank()
    ) +
    expand_limits(y = 0:1) +
    expand_limits(x = c(0, 100)) +
    labs(title = "The Likelihood", subtitle = "How well the curves fit the data") +
    theme_triptych(title_color = "#20235b")


  fit <- brm(
    model_formula,
    data = data,
    prior = c(prior_fixef, prior_phi),
    iter = 2000,
    seed = 12345,
    chains = 4,
    control = list(adapt_delta = 0.9, max_treedepth = 15)
  )

  draws_posterior <- data %>%
    expand(age = 0:100) %>%
    add_epred_draws(fit, ndraws = 100)

  p3 <- ggplot(draws_posterior) +
    aes(x = age, y = .epred) +
    geom_line(aes(group = .draw), alpha = .2) +
    geom_point(aes(y = prop), data = data,
               fill = "#247d3f", color = "white", size = 4, pch = 21) +
    theme(
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank()
    ) +
    expand_limits(y = 0:1) +
    labs(title = "The Posterior", subtitle = "Plausible curves after seeing the data") +
    theme_triptych(title_color = "#da7901")

  return(lst(p1, p2, p3))
}
