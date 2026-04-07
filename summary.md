# FIN451Golem Project Summary

## Project Overview
This is a Golem-based R Shiny application developed to analyze commodity forward curves, market volatility, co-dynamics, and seasonal impacts using historical data for Crude Oil (CL) and Natural Gas (NG), along with Treasury yields.

## Implemented Features

1.  **Yield Spreads**
    *   **Description**: Calculates and displays the difference (spread) between two selectable Treasury yield maturities over the full historical dataset.
    *   **Visualization**: Interactive `plotly` line chart.

2.  **Price History**
    *   **Description**: Displays the price or yield over the entire historical timeframe for a selected commodity (CL, NG) maturity or Treasury length.
    *   **Visualization**: Interactive `plotly` line chart.

2.  **Historical Forward Curve Analysis**
    *   **Description**: Visualizes the relationship between commodity prices and their months to maturity for a specific historical date.
    *   **Data Source**: `data.rda` (CL and NG series).
    *   **Visualization**: Interactive `plotly` line and point chart.

2.  **Volatility Across Maturity**
    *   **Description**: Displays the annualized volatility for different contract maturities (e.g., CL01 vs. CL36) to observe how price risk changes over time.
    *   **Calculation**: Log-returns and annualized standard deviation (sqrt(252)).
    *   **Visualization**: `plotly` bar chart.

3.  **Co-dynamics Across Markets**
    *   **Description**: Analyzes the relationship (correlation) between different markets, such as Oil vs. Natural Gas or Commodities vs. Treasury yields (selectable lengths: 3MO, 2Y, 5Y, 10Y, 30Y).
    *   **Calculation**: Inner join on dates followed by regression analysis on log-returns.
    *   **Visualization**: Scatter plot with a linear regression line.

4.  **Hedge Ratios (Minimum Variance)**
    *   **Description**: Calculates the optimal hedge ratio (MVHR) for various contract maturities relative to a selectable hedge instrument (any CL or NG contract maturity).
    *   **Calculation**: $$h^* = \rho \frac{\sigma_{target}}{\sigma_{hedge}}$$ using log-returns over a user-defined lookback period.
    *   **Visualization**: Multiple tabs showing the final MVHR, correlation, and volatility ratios across the term structure.

5.  **Seasonal Impacts**
    *   **Description**: Identifies monthly price and volatility patterns for selected contract maturities (01-36). It averages prices and calculates annualized volatility across multiple years to show typical seasonal trends and risk cycles.
    *   **Visualization**: Multi-year line chart for prices (with global average) and a bar chart for monthly volatility.

## Technical Details

*   **Framework**: `{golem}` for R package-based Shiny development.
*   **UI Architecture**: Built with `{bslib}` using a `page_navbar` layout and the "flatly" theme.
*   **Reactive Logic**: Efficient data filtering and transformation using `{dplyr}` and `{tidyr}`.
*   **Interactivity**: All plots are rendered with `{plotly}` for hover details and zooming.
*   **Dependencies Added**: `ggplot2`, `dplyr`, `tidyr`, `lubridate`, `bslib`, `plotly`.

## File Modifications

*   `DESCRIPTION`: Updated with new package dependencies.
*   `R/app_ui.R`: Simplified by calling modular UI functions.
*   `R/app_server.R`: Simplified by calling modular server functions.
*   `R/mod_forward_curve.R`: Modularized Historical Forward Curve logic.
*   `R/mod_volatility.R`: Modularized Volatility Across Maturity logic.
*   `R/mod_correlation.R`: Modularized Co-dynamics logic.
*   `R/mod_hedge_ratios.R`: Implemented Minimum Variance Hedge Ratio analysis.
*   `R/mod_seasonal.R`: Modularized Seasonal Impacts logic.
*   `R/utils_helpers.R`: Added shared helper function `extract_maturity`.
*   `R/commodity_forward_curve.R`: (Existing) Provided foundational cost-of-carry logic.

## Data Inventory
*   `data.rda`: Contains `data` (Date, Series, Value) covering 2007 to March 2026.
*   `yields.rda`: Contains `yields` (Symbol, Date, Price) for Treasury products.

---
*Created on: 2026-04-02 (Updated: 2026-04-03)*
