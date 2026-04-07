# Use a stable R base image (x86_64)
FROM rocker/r-ver:4.3.0

# Install system dependencies, including git for cloning
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /golem/work

# Define the mandatory VOLUME for Golem Network data transfers
VOLUME /golem/work

# Install CRAN dependencies
RUN R -e "install.packages(c('config', 'golem', 'shiny', 'ggplot2', 'dplyr', 'tidyr', 'lubridate', 'bslib', 'plotly', 'remotes'), repos='https://cloud.r-project.org/')"

# Clone the repository directly from GitHub and install it as a local package
RUN git clone https://github.com/JacobZ19/FIN451Golem.git /golem/app_source \
    && R -e "remotes::install_local('/golem/app_source', upgrade = 'never')"

# Document the Shiny port
EXPOSE 3838

# Default command to run the app
CMD ["R", "-e", "options('shiny.port'=3838, 'shiny.host'='0.0.0.0'); FIN451Golem::run_app()"]
