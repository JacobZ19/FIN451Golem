# Use a stable R base image (x86_64) compatible with Golem Providers
FROM rocker/r-ver:4.3.0

# Install system dependencies for R packages (required for plotly, bslib, and networking)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory for the application
WORKDIR /golem/work

# Define the mandatory VOLUME for Golem Network data transfers
VOLUME /golem/work

# Install CRAN dependencies
# Using a specific repo to ensure reproducibility across any OS
RUN R -e "install.packages(c('config', 'golem', 'shiny', 'ggplot2', 'dplyr', 'tidyr', 'lubridate', 'bslib', 'plotly', 'remotes'), repos='https://cloud.r-project.org/')"

# Copy the FIN451Golem package source into the container
COPY . /golem/app_source

# Clone from the repository
RUN git clone https://github.com/JacobZ19/FIN451Golem.git

# Document the Shiny port
EXPOSE 3838

# Default command to run the app
CMD ["R", "-e", "options('shiny.port'=3838, 'shiny.host'='0.0.0.0'); FIN451Golem::run_app()"]
