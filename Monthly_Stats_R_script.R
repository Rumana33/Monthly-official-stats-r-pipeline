#############################################
# Monthly_Stats_R_script.R
# Simple example of an automated pipeline
# for monthly official statistics in R
#############################################

#############################################
# Step-1: Scheduling & Monitoring (High-Level)
#
# This script is designed to be run automatically
# once per month using a scheduler such as:
# - Windows Task Scheduler
# - cron (Linux)
# - Internal NRS job scheduler / CI runner
#
# Example scheduling setup:
#   Rscript "C:/path/monthly_stats_example.R"
#
# Monitoring:
#   - The script prints a success message
#     ("Monthly update completed successfully.")
#   - Output files are timestamped and stored
#     in the /outputs folder.
#   - In a full RAP pipeline, logging or
#     email alerts can be added if needed.
#
# This prepares the script for reliable,
# automated monthly reporting.
#############################################

# Install packages if they are not installed
# Run this once in the Console (not in the script):
# install.packages("tidyverse")
# install.packages("lubridate")

# Load the tidyverse package for data handling and plotting
library(tidyverse)

# Load lubridate for working with dates
library(lubridate)

# Load readxl
library(readxl)

# --------------------------------------
# Step-2: Find and read the latest file
# --------------------------------------

# Helper function to read a single data file in various formats
read_data_file <- function(path) {
  ext <- tolower(tools::file_ext(path))
  
  if (ext == "csv") {
    readr::read_csv(path, show_col_types = FALSE)
  } else if (ext %in% c("tsv", "txt")) {
    readr::read_tsv(path, show_col_types = FALSE)
  } else if (ext %in% c("xlsx", "xls")) {
    readxl::read_excel(path)
  } else {
    stop("Unsupported file type: ", ext,
         ". Supported: csv, tsv, txt, xlsx, xls.")
  }
}

# Directory where input files are stored
data_dir <- "data"   

# List all supported files in the data directory
files <- list.files(
  data_dir,
  pattern = "\\.(csv|tsv|txt|xlsx|xls)$",
  full.names = TRUE,
  ignore.case = TRUE
)
if (length(files) == 0) {
  stop("No supported data files found in ", data_dir)
}

# Choose the most recent file by modification time
file_info <- file.info(files)
latest_file <- rownames(file_info)[which.max(file_info$mtime)]
message("Using latest data file: ", latest_file)

# Read the latest file into 'raw'
raw <- read_data_file(latest_file)


# ---------------------------------------------
# Step-3: Basic validation checks and  Cleaning
# ---------------------------------------------
# Validation checks
# Make column names lower-case so checks are case-insensitive
names(raw) <- tolower(names(raw))

# Define the columns we expect to see in the data (lower-case)
required_cols <- c("date", "age", "council_area")

if (!all(required_cols %in% names(raw))) {
  stop("Error: Missing one or more required columns in the input data.\n",
       "Expected columns (case-insensitive): ",
       paste(required_cols, collapse = ", "), "\n",
       "Found columns: ", paste(names(raw), collapse = ", "))
}

# Clean Data

# Create a new data frame called 'clean' with extra processed columns
clean <- mutate(
  raw,                           # Start from the original 'raw' data
  date = ymd(date),              # Convert the 'date' column to a proper Date type
  month = floor_date(date,       # Create a 'month' column by rounding each date
                     "month"),   #   down to the first day of its month
  age_group = case_when(         # Create a new 'age_group' column based on 'age'
    age < 20 ~ "0-19",           # If age is less than 20, label as "0-19"
    age < 40 ~ "20-39",          # If age is 20–39, label as "20-39"
    age < 65 ~ "40-64",          # If age is 40–64, label as "40-64"
    TRUE ~ "65+"                 # Otherwise (65 and above), label as "65+"
  )
)


# -------------------------------
# Step-4: Produce summary statistics
# -------------------------------

# Group the cleaned data by month, council_area and age_group
grouped_data <- group_by(
  clean,                         # Use the cleaned data frame
  month,                         # Group by 'month'
  council_area,                  # and by 'council_area'
  age_group                      # and by 'age_group'
)

# For each group, count how many rows (records) there are
monthly_summary <- summarise(
  grouped_data,                  # Use the grouped data
  n = n()                        # 'n' is the number of records in each group
)

# Remove the grouping information so 'monthly_summary' is a normal data frame
monthly_summary <- ungroup(monthly_summary)

# Total deaths per council area across the whole period
total_by_council <- count(
  clean,
  council_area,
  name = "total_deaths"
)

# Total deaths per age group (across the whole period)
total_by_age_group <- count(
  clean,
  age_group,
  name = "total_deaths_age"
)

# Total deaths overall (across all councils and months)
total_deaths_all <- nrow(clean)
# -------------------------------
# Save the summary for output
# -------------------------------

# Make sure the outputs folder exists (create it if it doesn't)
if (!dir.exists("outputs")) {
  dir.create("outputs")          # Create the "outputs" directory
}

# Save the summary table as a CSV file in the outputs folder
write_csv(
  monthly_summary,               # Data to save
  "outputs/monthly_statistics.csv"  # File path where it will be saved
)

# Save total deaths by council area
write_csv(
  total_by_council,
  "outputs/total_deaths_by_council.csv"
)

# Save total deaths per age group 
write_csv(
  total_by_age_group, 
  "outputs/total_deaths_by_age_group.csv")

# -------------------------------
# Step-5: Create a simple plot
# -------------------------------

# Count the total number of records per month
counts_by_month <- count(
  clean,                         # Use the cleaned data
  month                          # Count how many rows for each 'month'
)

# Create a line plot of counts by month
plot_monthly <- ggplot(
  counts_by_month,               # Data for the plot
  aes(x = month, y = n)          # Aesthetic mapping: month on x-axis, count 'n' on y-axis
) +
  geom_line() +                  # Draw a line to show how counts change over time
  labs(
    title = "Total Records per Month",  # Plot title
    x = "Month",                        # Label for x-axis
    y = "Number of records"            # Label for y-axis
  )

# Save the plot as a PNG file in the outputs folder
ggsave(
  filename = "outputs/monthly_plot.png",  # File path for the saved image
  plot = plot_monthly,                    # Plot object to save
  width = 6,                              # Width of the image in inches
  height = 4                              # Height of the image in inches
)

# Stacked bar plot: deaths per month by council area
plot_by_council <- ggplot(
  monthly_summary,
  aes(x = month, y = n, fill = council_area)
) +
  geom_col() +
  labs(
    title = "Deaths per Month by Council Area",
    x = "Month",
    y = "Number of deaths",
    fill = "Council area"
  )
# Save the plot as a PNG file in the outputs folder
ggsave(
  filename = "outputs/deaths_by_council_stacked.png",
  plot = plot_by_council,
  width = 6,
  height = 4
)

# Stacked bar by age group per month
plot_by_age <- ggplot(
  monthly_summary,
  aes(x = month, y = n, fill = age_group)
) +
  geom_col() +
  labs(
    title = "Deaths per Month by Age Group",
    x = "Month",
    y = "Number of deaths",
    fill = "Age group"
  )
# Save the plot as a PNG file in the outputs folder
ggsave(
  filename = "outputs/deaths_by_agegroup_stacked.png",
  plot = plot_by_age,
  width = 6,
  height = 4
)

# -------------------------------
# Finish
# -------------------------------

# Print a message to the console to confirm everything ran successfully
message("Monthly update completed successfully.")
