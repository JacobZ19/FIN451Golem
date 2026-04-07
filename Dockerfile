# Use a stable R base image (x86_64)
FROM rocker/r-ver:4.3.0

# Install system dependencies, including git for cloning
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*


# Install CRAN dependencies
RUN Rscript -e "install.packages('remotes', repos = 'https://cloud.r-project.org')"

WORKDIR /app

COPY DESCRIPTION NAMESPACE ./

RUN Rscript -e "remotes::install_deps(dependencies = c('Imports', 'Depends'), upgrade = 'never')"

COPY . .

RUN R CMD INSTALL --no-multiarch --with-keep.source .

# Document the Shiny port
EXPOSE 3838

# Default command to run the app
CMD ["R", "-e", "options('shiny.port'=3838, 'shiny.host'='0.0.0.0'); FIN451Golem::run_app()"]