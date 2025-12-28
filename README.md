# Queensland Long-Term Health Conditions Explorer

A Shiny web application for exploring 2021 Census data on long-term health conditions across Queensland, Australia.

## Overview

This application visualises data from the Australian Bureau of Statistics (ABS) 2021 Census of Population and Housing, allowing users to explore the prevalence of long-term health conditions across different geographic areas in Queensland.

## Features

### Geographic Filtering

- **Multiple geography levels**: View data at SA2, SA3, or SA4 level
- **PHN filtering**: Optionally limit results to a specific Primary Health Network
- **SA4 filtering**: Optionally limit results to a specific SA4 region
- **Multi-area comparison**: Select multiple areas to compare side-by-side

### Health Conditions Tracked

- Arthritis
- Asthma
- Cancer (including remission)
- Dementia (including Alzheimer's)
- Diabetes (excluding gestational diabetes)
- Heart disease (including heart attack or angina)
- Kidney disease
- Lung condition (including COPD or emphysema)
- Mental health condition (including depression or anxiety)
- Stroke
- Any other long-term health condition(s)
- No long-term health condition(s)

### Visualisation Options

#### Health Conditions Comparison Tab

- Compare prevalence of all health conditions across selected areas
- Filter by sex (Persons, Males, Females)
- Filter by age group (Total or specific age brackets)
- Toggle between raw counts and percentage of population
- Option to exclude "No condition" from the chart

#### By Age Group Tab

- View condition prevalence broken down by age group
- Compare Males vs Females side-by-side
- Select a specific condition or view "Any condition" aggregate
- Faceted display for multi-area comparison

#### Condition Detail Tab

- Deep dive into a specific health condition
- Age group breakdown with sex comparison
- Prevalence patterns across the lifespan

### Display Options

- **Show as percentage**: Display values as percentage of total population
- **Show as counts**: Display raw person counts
- **Exclude "No condition"**: Focus on health conditions only

## Data Source

- **Source**: ABS 2021 Census of Population and Housing
- **License**: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- **Note**: Small random adjustments have been applied by ABS to cell values for privacy protection

## Technical Details

### Requirements

- R (≥ 4.0)
- Required packages:
  - `shiny`
  - `tidyverse`
  - `arrow`
  - `scales`

### Data Format

The application reads data from a Parquet file (`data/qld_health_analysis.parquet`) containing:

- Geographic identifiers (SA2, SA3, SA4, PHN)
- Sex breakdowns (Persons, Males, Females)
- Age group breakdowns (9 age brackets plus Total)
- Long-term health condition categories
- Person counts

### Running the App

```r
# Install required packages
install.packages(c("shiny", "tidyverse", "arrow", "scales"))

# Run the app
shiny::runApp()
```

## Project Structure

```
ABS_APP/
├── app.R                              # Main Shiny application
├── data/
│   └── qld_health_analysis.parquet   # Census health data
└── README.md                          # This file
```

## Notes

- Respondents could report multiple long-term health conditions, so percentages may sum to more than 100%
- Due to ABS privacy perturbation, sum of subgroups may not exactly match totals
- The "Total (Persons)" category is used as the population denominator for percentage calculations

## License

Data is sourced from the Australian Bureau of Statistics and is licensed under [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
