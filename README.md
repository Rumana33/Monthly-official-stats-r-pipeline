# Monthly-official-stats-r-pipeline
Automated, reproducible R pipeline for monthly official statistics. Ingests CSV/Excel data, validates and cleans records, computes summary statistics, generates plots, and produces an auto-updating R Markdown report. Designed for scheduled monthly runs.
## What this script does
When you run the script, it will:
1. Find the **latest** data file inside the `data/` folder.  
2. Check the file has the right columns.  
3. Clean the data and create:
   - `month`
   - `age_group` (0–19, 20–39, 40–64, 65+)  
4. Create summary tables (counts).
5. Create plots (graphs).
6. Save everything in the `outputs/` folder.
## Files and folders
.
├── data/ # Put your monthly data files here
├── outputs/ # The script saves results here
└── monthly_stats_example.R # The R script you run
## What data you need
Your data file must contain these columns (names can be upper/lower case):

- `date` (example: 2025-01-05)
- `age` (example: 72)
- `council_area` (example: Glasgow City)
## Example CSV:
date,age,council_area
2025-01-05,34,Glasgow City
2025-01-07,72,Glasgow City
2025-01-10,19,Edinburgh
## What you will get after running
The script creates an outputs/ folder (if it does not exist) and saves:
CSV files
•	monthly_statistics.csv
•	total_deaths_by_council.csv
•	total_deaths_by_age_group.csv
Plot images (PNG)
•	monthly_plot.png
•	deaths_by_council_stacked.png
•	deaths_by_agegroup_stacked.png
## How to run the script
Option 1: Run in RStudio
Open Monthly_Stats_R_script.R and click Run.
Option 2: Run in Command Prompt / Terminal
Go to the project folder and run:
Rscript Monthly_Stats_R_script.R
If it works, you will see:
Monthly update completed successfully.
## Packages needed
This script uses these R packages:
•	tidyverse
•	lubridate
•	readxl
Install them once:
install.packages(c("tidyverse", "lubridate", "readxl"))
## Monthly automation 
This script can be scheduled to run once per month using:
•	Windows Task Scheduler
•	cron (Linux)

