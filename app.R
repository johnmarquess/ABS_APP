library(shiny)
library(tidyverse)
library(arrow)
library(scales)

# ------------------------------------------------------------------------------
# Data prep --------------------------------------------------------------------
# ------------------------------------------------------------------------------

# Load health data
health_data <- read_parquet("data/qld_health_analysis.parquet")

# Define color palette
color_palette <- c(
    dark_blue = "#05325F",
    dark_green = "#008635",
    deep_crimson = "#A50034",
    grey_dark = "#78797E",
    vibrant_orange = "#ffbf00",
    sapphire_blue = "#09549F",
    light_blue = "#0085B3",
    light_green = "#6BBE27"
)

palette_for <- function(names_vec) {
    labs <- unique(names_vec)
    vals <- rep_len(color_palette, length(labs))
    names(vals) <- labs
    vals
}

# Health condition order (excluding Total and Not stated for main display)
health_conditions <- c(
    "Arthritis",
    "Asthma",
    "Cancer (including remission)",
    "Dementia (including Alzheimer's)",
    "Diabetes (excluding gestational diabetes)",
    "Heart disease (including heart attack or angina)",
    "Kidney disease",
    "Lung condition (including COPD or emphysema)",
    "Mental health condition (including depression or anxiety)",
    "Stroke",
    "Any other long-term health condition(s)",
    "No long-term health condition(s)"
)

# Short labels for display
health_labels <- c(
    "Arthritis" = "Arthritis",
    "Asthma" = "Asthma",
    "Cancer (including remission)" = "Cancer",
    "Dementia (including Alzheimer's)" = "Dementia",
    "Diabetes (excluding gestational diabetes)" = "Diabetes",
    "Heart disease (including heart attack or angina)" = "Heart Disease",
    "Kidney disease" = "Kidney Disease",
    "Lung condition (including COPD or emphysema)" = "Lung Condition",
    "Mental health condition (including depression or anxiety)" = "Mental Health",
    "Stroke" = "Stroke",
    "Any other long-term health condition(s)" = "Other Condition",
    "No long-term health condition(s)" = "No Condition"
)

# Age group order
age_levels <- c(
    "0-14 years", "15-24 years", "25-34 years", "35-44 years",
    "45-54 years", "55-64 years", "65-74 years", "75-84 years", "85 plus"
)

# Geography lookup
geo_lookup <- list(
    SA2 = list(code = "sa2_code", name = "sa2_name", label = "SA2"),
    SA3 = list(code = "sa3_code", name = "sa3_name", label = "SA3"),
    SA4 = list(code = "sa4_code", name = "sa4_name", label = "SA4")
)

# Get unique values for dropdowns
phn_choices <- health_data$PHN_NAME_2023 |>
    unique() |>
    sort() |>
    purrr::discard(is.na)

sa4_choices <- health_data$sa4_name |>
    unique() |>
    sort() |>
    purrr::discard(is.na)

# ------------------------------------------------------------------------------
# UI ---------------------------------------------------------------------------
# ------------------------------------------------------------------------------
ui <- fluidPage(
    tags$head(
        tags$link(
            href = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
            rel = "stylesheet",
            integrity = "sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH",
            crossorigin = "anonymous"
        ),
        tags$style(HTML("
      body {
        font-size: 14px;
      }
      .app-navbar {
        background: radial-gradient(1200px circle at 10% 10%, rgba(13,110,253,.18), transparent 40%),
                    radial-gradient(900px circle at 90% 20%, rgba(25,135,84,.14), transparent 40%),
                    linear-gradient(180deg, #0b1220 0%, #0f172a 100%);
        padding: 20px 20px 16px 20px;
        margin: -10px -15px 20px -15px;
      }
      .app-navbar .btn {
        font-size: 1rem;
        padding: 8px 16px;
      }
    "))
    ),
    tags$div(
        class = "app-navbar d-flex gap-2",
        tags$a(
            href = "/",
            class = "btn btn-outline-light",
            "\u2190 Home"
        ),
        tags$a(
            href = "https://github.com/johnmarquess/ABS_APP",
            target = "_blank",
            class = "btn btn-outline-light",
            style = "margin-left: 8px;",
            "GitHub"
        )
    ),
    titlePanel("Queensland Long-Term Health Conditions"),
    p("Explore 2021 Census data on long-term health conditions across Queensland. Select a PHN or SA4 to filter geographies, then choose areas to compare health condition prevalence."),
    sidebarLayout(
        sidebarPanel(
            selectInput(
                "phn_filter",
                "Limit to PHN (optional)",
                choices = c("All PHNs", phn_choices),
                selected = "Brisbane North"
            ),
            selectInput(
                "sa4_filter",
                "Limit to SA4 (optional)",
                choices = c("All SA4s", sa4_choices),
                selected = "All SA4s"
            ),
            selectInput(
                "geo_level",
                "Geography level",
                choices = names(geo_lookup),
                selected = "SA3"
            ),
            uiOutput("geo_selector"),
            conditionalPanel(
                condition = "input.tabset == 'comparison'",
                radioButtons(
                    "age_category",
                    "Age category",
                    choices = c("All ages" = "all", "Under 65" = "under65", "65 and over" = "65plus", "Custom" = "custom"),
                    selected = "all",
                    inline = TRUE
                )
            ),
            conditionalPanel(
                condition = "input.tabset == 'comparison' && input.age_category == 'custom'",
                selectInput(
                    "age_groups",
                    "Select age groups",
                    choices = c("Total", age_levels),
                    selected = "Total",
                    multiple = TRUE
                )
            ),
            checkboxInput(
                "show_percent",
                "Show as percentage of selected population",
                value = TRUE
            ),
            checkboxInput(
                "exclude_no_condition",
                "Exclude 'No condition' from chart",
                value = TRUE
            ),
            hr(),
            helpText("Data source: ABS 2021 Census of Population and Housing")
        ),
        mainPanel(
            tabsetPanel(
                id = "tabset",
                selected = "comparison",
                tabPanel(
                    "Health Conditions Comparison",
                    value = "comparison",
                    radioButtons(
                        "comparison_sex",
                        "Sex",
                        choices = c("Persons", "Males", "Females"),
                        selected = "Persons",
                        inline = TRUE
                    ),
                    plotOutput("comparison_plot", height = "600px")
                ),
                tabPanel(
                    "By Age Group",
                    value = "age",
                    selectInput(
                        "age_condition",
                        "Select condition",
                        choices = c("Any condition" = "any", setNames(health_conditions[health_conditions != "No long-term health condition(s)"], health_labels[health_conditions[health_conditions != "No long-term health condition(s)"]])),
                        selected = "any"
                    ),
                    plotOutput("age_plot", height = "600px")
                ),
                tabPanel(
                    "Condition Detail",
                    value = "detail",
                    selectInput(
                        "selected_condition",
                        "Select condition to detail",
                        choices = health_conditions[health_conditions != "No long-term health condition(s)"],
                        selected = "Mental health condition (including depression or anxiety)"
                    ),
                    plotOutput("detail_plot", height = "500px")
                )
            ),
            tags$div(
                style = "text-align: left; margin-top: 12px;",
                tags$small(
                    HTML(paste0(
                        "<ul style='margin:0 0 0 18px; padding-left: 16px;'>",
                        "<li>Based on <i>ABS 2021 Census of Population and Housing</i>, licensed under <a href='https://creativecommons.org/licenses/by/4.0/'>CC BY 4.0</a>.</li>",
                        "<li>Respondents could report multiple long-term health conditions. Percentages represent proportion of people in the area.</li>",
                        "<li>Small random changes have been made to cell values for privacy reasons.</li>",
                        "</ul>"
                    ))
                )
            )
        )
    )
)

# ------------------------------------------------------------------------------
# Server -----------------------------------------------------------------------
# ------------------------------------------------------------------------------
server <- function(input, output, session) {
    geo_col <- function(level, field = "name") {
        geo_lookup[[level]][[field]]
    }

    # Update SA4 choices based on PHN filter
    sa4_choices_by_phn <- reactive({
        data <- health_data
        if (!is.null(input$phn_filter) && input$phn_filter != "All PHNs") {
            data <- filter(data, PHN_NAME_2023 == input$phn_filter)
        }
        choices <- data$sa4_name |>
            unique() |>
            sort()
        choices[!is.na(choices)]
    })

    # Available geographies based on filters
    available_geos <- reactive({
        data <- health_data

        if (!is.null(input$phn_filter) && input$phn_filter != "All PHNs") {
            data <- filter(data, PHN_NAME_2023 == input$phn_filter)
        }

        if (!is.null(input$sa4_filter) && input$sa4_filter != "All SA4s") {
            data <- filter(data, sa4_name == input$sa4_filter)
        }

        level_col <- geo_col(input$geo_level, "name")
        choices <- data |>
            filter(!is.na(.data[[level_col]])) |>
            arrange(.data[[level_col]]) |>
            pull(level_col) |>
            unique()

        choices
    })

    # Update SA4 dropdown when PHN changes
    observeEvent(input$phn_filter,
        {
            choices <- c("All SA4s", sa4_choices_by_phn())
            current <- input$sa4_filter
            new_selection <- if (current %in% choices) current else "All SA4s"
            updateSelectInput(session, "sa4_filter", choices = choices, selected = new_selection)
        },
        ignoreInit = FALSE
    )

    # Update geography selector
    observeEvent(list(input$geo_level, input$sa4_filter, input$phn_filter),
        {
            choices <- available_geos()
            default_sel <- head(choices, n = min(3, length(choices)))
            updateSelectInput(session, "geos", choices = choices, selected = default_sel)
        },
        ignoreNULL = FALSE
    )

    output$geo_selector <- renderUI({
        choices <- available_geos()
        initial_sel <- head(choices, n = min(3, length(choices)))
        selectInput(
            "geos",
            paste0("Select ", geo_lookup[[input$geo_level]]$label, "(s) to compare"),
            choices = choices,
            selected = initial_sel,
            multiple = TRUE
        )
    })

    # Helper to get selected age groups based on age_category
    get_selected_ages <- reactive({
        age_cat <- input$age_category
        if (is.null(age_cat) || age_cat == "all") {
            return("Total")
        } else if (age_cat == "under65") {
            return(c("0-14 years", "15-24 years", "25-34 years", "35-44 years", "45-54 years", "55-64 years"))
        } else if (age_cat == "65plus") {
            return(c("65-74 years", "75-84 years", "85 plus"))
        } else {
            # Custom selection
            selected <- input$age_groups
            if (is.null(selected) || "Total" %in% selected) {
                return("Total")
            }
            return(selected)
        }
    })

    # Filter data based on selections
    filtered_data <- reactive({
        req(input$geos, input$comparison_sex)

        level_name <- geo_col(input$geo_level, "name")

        # Handle age group selection
        selected_ages <- get_selected_ages()

        data <- health_data |>
            filter(geog_type == input$geo_level) |>
            filter(sex_name == input$comparison_sex) |>
            filter(age_group_label %in% selected_ages) |>
            filter(.data[[level_name]] %in% input$geos) |>
            filter(long_term_health_condition %in% health_conditions) |>
            # Always aggregate to ensure unique rows per geo + condition
            group_by(across(c(all_of(level_name), long_term_health_condition))) |>
            summarise(persons = sum(persons, na.rm = TRUE), .groups = "drop")

        data
    })

    # Get total population for percentage calculations
    total_population <- reactive({
        req(input$geos, input$comparison_sex)

        level_name <- geo_col(input$geo_level, "name")

        selected_ages <- get_selected_ages()

        data <- health_data |>
            filter(geog_type == input$geo_level) |>
            filter(sex_name == input$comparison_sex) |>
            filter(age_group_label %in% selected_ages) |>
            filter(.data[[level_name]] %in% input$geos) |>
            filter(long_term_health_condition == "Total (Persons)") |>
            group_by(across(all_of(level_name))) |>
            summarise(total = sum(persons, na.rm = TRUE), .groups = "drop")

        data
    })

    # Comparison bar chart
    output$comparison_plot <- renderPlot({
        df <- filtered_data()
        totals <- total_population()
        req(nrow(df) > 0)

        level_name <- geo_col(input$geo_level, "name")

        # Exclude "No condition" if selected
        conditions_to_show <- if (isTRUE(input$exclude_no_condition)) {
            health_conditions[health_conditions != "No long-term health condition(s)"]
        } else {
            health_conditions
        }

        plot_data <- df |>
            filter(long_term_health_condition %in% conditions_to_show) |>
            rename(geo_name = all_of(level_name)) |>
            left_join(totals |> rename(geo_name = all_of(level_name)), by = "geo_name") |>
            mutate(
                pct = persons / total * 100,
                condition_short = health_labels[long_term_health_condition],
                condition_short = factor(condition_short, levels = health_labels[conditions_to_show]),
                # Create formatted label for display
                label = if (isTRUE(input$show_percent)) {
                    sprintf("%.1f%%", pct)
                } else {
                    comma(persons)
                }
            )

        y_var <- if (isTRUE(input$show_percent)) "pct" else "persons"
        y_label <- if (isTRUE(input$show_percent)) "Percentage (%)" else "Number of Persons"

        # Get age label for subtitle
        age_label <- switch(input$age_category,
            "all" = "All ages",
            "under65" = "Under 65",
            "65plus" = "65 and over",
            "custom" = paste(input$age_groups, collapse = ", ")
        )

        palette_vals <- palette_for(plot_data$geo_name)

        ggplot(plot_data, aes(x = condition_short, y = .data[[y_var]], fill = geo_name)) +
            geom_col(position = position_dodge(width = 0.8), width = 0.7) +
            geom_text(
                aes(label = label),
                position = position_dodge(width = 0.8),
                hjust = -0.1,
                size = 3
            ) +
            scale_fill_manual(values = palette_vals) +
            scale_y_continuous(
                labels = if (isTRUE(input$show_percent)) number_format(accuracy = 0.1) else comma,
                expand = expansion(mult = c(0, 0.15))
            ) +
            coord_flip() +
            labs(
                x = NULL,
                y = y_label,
                fill = geo_lookup[[input$geo_level]]$label,
                title = "Long-Term Health Conditions by Area",
                subtitle = paste(input$comparison_sex, "| Age:", age_label)
            ) +
            theme_minimal(base_size = 13) +
            theme(
                legend.position = "bottom",
                axis.text.y = element_text(size = 11),
                plot.title = element_text(face = "bold")
            )
    })

    # Age group breakdown plot
    output$age_plot <- renderPlot({
        req(input$geos, input$age_condition)

        level_name <- geo_col(input$geo_level, "name")

        # Get data for Males and Females (not Persons) for all age groups
        data <- health_data |>
            filter(geog_type == input$geo_level) |>
            filter(sex_name %in% c("Males", "Females")) |>
            filter(age_group_label %in% age_levels) |>
            filter(.data[[level_name]] %in% input$geos) |>
            filter(long_term_health_condition != "Total (Persons)") |>
            filter(long_term_health_condition != "Not stated")

        # Filter by selected condition or aggregate all conditions
        if (input$age_condition == "any") {
            # Exclude "No condition" for "any condition" view
            data <- data |>
                filter(long_term_health_condition != "No long-term health condition(s)")
            condition_title <- "Any Long-Term Health Condition"
        } else {
            data <- data |>
                filter(long_term_health_condition == input$age_condition)
            condition_title <- health_labels[input$age_condition]
        }

        # Get totals per area per age group per sex
        totals_by_age <- health_data |>
            filter(geog_type == input$geo_level) |>
            filter(sex_name %in% c("Males", "Females")) |>
            filter(age_group_label %in% age_levels) |>
            filter(.data[[level_name]] %in% input$geos) |>
            filter(long_term_health_condition == "Total (Persons)") |>
            group_by(across(all_of(level_name)), age_group_label, sex_name) |>
            summarise(total = sum(persons, na.rm = TRUE), .groups = "drop")

        plot_data <- data |>
            rename(geo_name = all_of(level_name)) |>
            group_by(geo_name, age_group_label, sex_name) |>
            summarise(persons_with_condition = sum(persons, na.rm = TRUE), .groups = "drop") |>
            left_join(
                totals_by_age |> rename(geo_name = all_of(level_name)),
                by = c("geo_name", "age_group_label", "sex_name")
            ) |>
            mutate(
                pct = persons_with_condition / total * 100,
                age_group_label = factor(age_group_label, levels = age_levels)
            )

        y_var <- if (isTRUE(input$show_percent)) "pct" else "persons_with_condition"
        y_label <- if (isTRUE(input$show_percent)) "Percentage (%)" else "Number of Persons"

        # Use sex for coloring
        sex_palette <- c("Males" = "#09549F", "Females" = "#A50034")

        ggplot(plot_data, aes(x = age_group_label, y = .data[[y_var]], fill = sex_name)) +
            geom_col(position = position_dodge(width = 0.8), width = 0.7) +
            scale_fill_manual(values = sex_palette) +
            scale_y_continuous(labels = if (isTRUE(input$show_percent)) number_format(accuracy = 0.1) else comma) +
            facet_wrap(~geo_name, scales = "free_y") +
            labs(
                x = "Age Group",
                y = y_label,
                fill = "Sex",
                title = condition_title,
                subtitle = paste("Prevalence by age group and sex |", geo_lookup[[input$geo_level]]$label, "comparison")
            ) +
            theme_minimal(base_size = 13) +
            theme(
                legend.position = "bottom",
                axis.text.x = element_text(angle = 45, hjust = 1),
                plot.title = element_text(face = "bold"),
                strip.text = element_text(face = "bold")
            )
    })

    # Detail plot for specific condition
    output$detail_plot <- renderPlot({
        req(input$geos, input$selected_condition)

        level_name <- geo_col(input$geo_level, "name")

        # Get data for Males and Females for selected condition across age groups
        data <- health_data |>
            filter(geog_type == input$geo_level) |>
            filter(sex_name %in% c("Males", "Females")) |>
            filter(age_group_label %in% age_levels) |>
            filter(.data[[level_name]] %in% input$geos) |>
            filter(long_term_health_condition == input$selected_condition)

        # Get totals per area per age group per sex
        totals_by_age <- health_data |>
            filter(geog_type == input$geo_level) |>
            filter(sex_name %in% c("Males", "Females")) |>
            filter(age_group_label %in% age_levels) |>
            filter(.data[[level_name]] %in% input$geos) |>
            filter(long_term_health_condition == "Total (Persons)") |>
            group_by(across(all_of(level_name)), age_group_label, sex_name) |>
            summarise(total = sum(persons, na.rm = TRUE), .groups = "drop")

        plot_data <- data |>
            rename(geo_name = all_of(level_name)) |>
            left_join(
                totals_by_age |> rename(geo_name = all_of(level_name)),
                by = c("geo_name", "age_group_label", "sex_name")
            ) |>
            mutate(
                pct = persons / total * 100,
                age_group_label = factor(age_group_label, levels = age_levels)
            )

        y_var <- if (isTRUE(input$show_percent)) "pct" else "persons"
        y_label <- if (isTRUE(input$show_percent)) "Percentage (%)" else "Number of Persons"

        # Use sex for coloring
        sex_palette <- c("Males" = "#09549F", "Females" = "#A50034")

        ggplot(plot_data, aes(x = age_group_label, y = .data[[y_var]], fill = sex_name)) +
            geom_col(position = position_dodge(width = 0.8), width = 0.7) +
            scale_fill_manual(values = sex_palette) +
            scale_y_continuous(labels = if (isTRUE(input$show_percent)) number_format(accuracy = 0.1) else comma) +
            facet_wrap(~geo_name, scales = "free_y") +
            labs(
                x = "Age Group",
                y = y_label,
                fill = "Sex",
                title = health_labels[input$selected_condition],
                subtitle = paste("Prevalence by age group and sex |", geo_lookup[[input$geo_level]]$label, "comparison")
            ) +
            theme_minimal(base_size = 13) +
            theme(
                legend.position = "bottom",
                axis.text.x = element_text(angle = 45, hjust = 1),
                plot.title = element_text(face = "bold"),
                strip.text = element_text(face = "bold")
            )
    })
}

shinyApp(ui, server)
