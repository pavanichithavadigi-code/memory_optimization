# =============================================================================
# TASK 25: ASSESS MEMORY USAGE FOR LARGE DATASETS
# Beginner-friendly practical exercise for R programming
# =============================================================================

# =============================================================================
# SECTION 0: PREPARE THE R ENVIRONMENT AND PROJECT FOLDERS
# =============================================================================

# Remove objects from a previous run if required.
# Uncomment the next line only if you want to clear your R environment.
rm(list = ls())

# Set a seed so that the synthetic data can be reproduced.
set.seed(2026)

# Create all project folders automatically.
project_folders <- c(
  "data",
  "results",
  "documentation"
)

for (folder in project_folders) {
  dir.create(
    folder,
    recursive = TRUE,
    showWarnings = FALSE
  )
}

cat("\nTASK 25: MEMORY OPTIMIZATION\n")
cat("===========================\n")
cat("Working directory:", getwd(), "\n")

# We use data.table for one of the memory-saving examples.
# Install it only if it is not already available.
if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages(
    "data.table",
    repos = "https://cloud.r-project.org"
  )
}

library(data.table)

cat("\nR version:\n")
print(R.version.string)

cat("\ndata.table version:\n")
print(packageVersion("data.table"))


# =============================================================================
# SECTION 1: CREATE SYNTHETIC CLINICAL-STYLE DATASETS
# Corresponds to: 01_create_data.R
# =============================================================================

# We create two simplified datasets:
#
# ADSL: one record per subject.
# ADLB: multiple laboratory records per subject.
#
# These are training datasets only. They are not complete CDISC datasets.

cat("\nSECTION 1: CREATING SYNTHETIC DATA\n")

number_of_subjects <- 100000
number_of_lab_records <- 1000000

# ---------------------------------------------------------------------------
# 1.1 Create ADSL
# ---------------------------------------------------------------------------

adsl <- data.frame(
  USUBJID = sprintf(
    "SUBJ%06d",
    seq_len(number_of_subjects)
  ),
  AGE = sample(
    18:80,
    number_of_subjects,
    replace = TRUE
  ),
  SEX = sample(
    c("M", "F"),
    number_of_subjects,
    replace = TRUE
  ),
  TRT01A = sample(
    c("Placebo", "Drug A", "Drug B"),
    number_of_subjects,
    replace = TRUE
  ),
  COUNTRY = sample(
    c("India", "USA", "UK", "Germany"),
    number_of_subjects,
    replace = TRUE
  ),
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# 1.2 Create ADLB
# ---------------------------------------------------------------------------

# Each laboratory record belongs to one subject.
# The subject identifier is selected from ADSL.

adlb <- data.frame(
  USUBJID = sample(
    adsl$USUBJID,
    number_of_lab_records,
    replace = TRUE
  ),
  PARAMCD = sample(
    c("ALT", "AST", "HB", "WBC", "CREAT"),
    number_of_lab_records,
    replace = TRUE
  ),
  AVAL = round(
    rnorm(
      number_of_lab_records,
      mean = 50,
      sd = 12
    ),
    2
  ),
  VISIT = sample(
    c("Baseline", "Week 4", "Week 8", "Week 12"),
    number_of_lab_records,
    replace = TRUE
  ),
  stringsAsFactors = FALSE
)

# Save the synthetic datasets.
write.csv(
  adsl,
  "data/synthetic_adsl.csv",
  row.names = FALSE
)

write.csv(
  adlb,
  "data/synthetic_adlb.csv",
  row.names = FALSE
)

cat("ADSL rows:", nrow(adsl), "\n")
cat("ADLB rows:", nrow(adlb), "\n")
cat("Synthetic datasets saved in the data folder.\n")

# Basic structure checks.
cat("\nADSL structure:\n")
str(adsl)

cat("\nADLB structure:\n")
str(adlb)


# =============================================================================
# SECTION 2: CHECK MEMORY USAGE OF R OBJECTS
# Corresponds to: 02_check_memory_usage.R
# =============================================================================

cat("\nSECTION 2: CHECKING MEMORY USAGE\n")

# object.size() gives an approximate size of an R object in bytes.
# format() makes the size easier to read.

adsl_size_bytes <- as.numeric(object.size(adsl))
adlb_size_bytes <- as.numeric(object.size(adlb))

adsl_size_mb <- adsl_size_bytes / (1024^2)
adlb_size_mb <- adlb_size_bytes / (1024^2)

cat("\nADSL object size:\n")
print(format(object.size(adsl), units = "auto"))

cat("\nADLB object size:\n")
print(format(object.size(adlb), units = "auto"))

# Create a small summary table of object sizes.
object_size_summary <- data.frame(
  OBJECT = c("ADSL", "ADLB"),
  ROWS = c(nrow(adsl), nrow(adlb)),
  SIZE_BYTES = c(adsl_size_bytes, adlb_size_bytes),
  SIZE_MB = round(c(adsl_size_mb, adlb_size_mb), 2),
  stringsAsFactors = FALSE
)

print(object_size_summary)

write.csv(
  object_size_summary,
  "results/object_size_summary.csv",
  row.names = FALSE
)

# gc() reports memory information for the current R session.
# It can also ask R to perform garbage collection.
cat("\nGarbage collection information before cleanup:\n")
gc_before <- gc()
print(gc_before)

# Optional: if lobstr is installed, obj_size() can provide another
if (requireNamespace("lobstr", quietly = TRUE)) {
  cat("\nlobstr::obj_size() results:\n")
  print(lobstr::obj_size(adsl))
  print(lobstr::obj_size(adlb))
} else {
  cat(
    "\nOptional package 'lobstr' is not installed. ",
    "The base R object.size() results above are sufficient for this exercise.\n"
  )
}


# =============================================================================
# SECTION 3: UNDERSTAND OBJECT COPIES
# Corresponds to: 03_understand_object_copies.R
# =============================================================================

cat("\nSECTION 3: UNDERSTANDING OBJECT COPIES\n")

# R uses copy-on-modify behaviour in many common situations.
# This means that when an object is modified, R may create another copy
# so that the original value can be preserved.
#
# The exact copying behaviour depends on the object and operation.
# We will use a small example first.

small_data <- data.frame(
  ID = 1:5,
  VALUE = c(10, 20, 30, 40, 50)
)

# Assigning one object to another does not necessarily copy all data
# immediately. R can share the underlying data until a modification occurs.
small_data_copy <- small_data

cat("\nOriginal small_data:\n")
print(small_data)

cat("\nsmall_data_copy before modification:\n")
print(small_data_copy)

# Modify the copy.
small_data_copy$VALUE[1] <- 999

cat("\nsmall_data after modifying small_data_copy:\n")
print(small_data)

cat("\nsmall_data_copy after modification:\n")
print(small_data_copy)

# Notice that the original object remains unchanged.
# This is the important behavior to understand.

# ---------------------------------------------------------------------------
# 3.1 Demonstrate a copy with a larger object
# ---------------------------------------------------------------------------

# Create a separate copy of ADSL for this demonstration.
adsl_copy <- adsl

cat("\nApproximate size of adsl:\n")
print(format(object.size(adsl), units = "auto"))

cat("\nApproximate size of adsl_copy:\n")
print(format(object.size(adsl_copy), units = "auto"))

# Modify one column in the copied data frame.
# R may need to duplicate data as part of this modification.
adsl_copy$AGE_CATEGORY <- ifelse(
  adsl_copy$AGE < 40,
  "Below 40",
  "40 and above"
)

cat("\nOriginal ADSL columns:\n")
print(names(adsl))

cat("\nCopied ADSL columns:\n")
print(names(adsl_copy))


cat("\nApproximate size of adsl:\n")
print(format(object.size(adsl), units = "auto"))

cat("\nApproximate size of adsl_copy:\n")
print(format(object.size(adsl_copy), units = "auto"))


cat("\nbefore removing adsl_copy, run gc():\n")
gc()

# The original ADSL does not contain AGE_CATEGORY.
# Remove the demonstration copy so it does not remain in memory.
rm(adsl_copy)

cat("\nAfter removing adsl_copy, run gc():\n")
gc()


# =============================================================================
# SECTION 4: APPLY SIMPLE MEMORY-SAVING TECHNIQUES
# Corresponds to: 04_optimize_memory_usage.R
# =============================================================================

cat("\nSECTION 4: MEMORY-SAVING TECHNIQUES\n")

# Technique 1:
# Keep only the columns required for the next analysis.
#
# A large dataset may contain many columns that are not needed.
# Creating a smaller working dataset can reduce the amount of data
# carried through later steps.

adlb_small <- adlb[
  ,
  c("USUBJID", "PARAMCD", "AVAL")
]

cat("\nFull ADLB size:\n")
print(format(object.size(adlb), units = "auto"))

cat("\nADLB with only three required columns:\n")
print(format(object.size(adlb_small), units = "auto"))

# Technique 2:
# Use data.table reference modification with :=.
#
# setDT() converts a data frame to a data.table by reference.
# The := operator adds or changes a column by reference.
# This can avoid some copies that may occur with repeated data-frame
# modification. It also changes the data.table object itself.

adsl_dt <- data.table::as.data.table(adsl)

cat("\nADSL data.table size before adding a column:\n")
print(format(object.size(adsl_dt), units = "auto"))

# Add a derived column by reference.
adsl_dt[
  ,
  AGE_CATEGORY := fifelse(
    AGE < 40,
    "Below 40",
    "40 and above"
  )
]

cat("\nADSL data.table size after adding a column:\n")
print(format(object.size(adsl_dt), units = "auto"))

# Check that the new column was created.
print(head(adsl_dt))

# Technique 3:
# Remove objects that are no longer required.
#
# rm() removes an object name from the current environment.
# gc() asks R to perform garbage collection.
#
# Removing an object does not guarantee that the operating system
# immediately receives all memory back. R manages memory internally.

rm(adlb_small)
gc()

# Technique 4:
# Read only the columns needed from a CSV file.
#
# fread() from data.table supports selecting columns during import.
# This avoids loading columns that are not required for the analysis.

adlb_selected <- data.table::fread(
  "data/synthetic_adlb.csv",
  select = c("USUBJID", "PARAMCD", "AVAL")
)

cat("\nSize of full ADLB data frame:\n")
print(format(object.size(adlb), units = "auto"))

cat("\nSize of selected-column ADLB import:\n")
print(format(object.size(adlb_selected), units = "auto"))

# ---------------------------------------------------------------------------
# 4.1 Chunk processing demonstration
# ---------------------------------------------------------------------------

# Chunk processing can be useful when a file is too large to comfortably
# load into memory all at once.
#
# We process the ADLB CSV in smaller groups of lines and calculate
# PARAMCD record counts and sums. We then combine the partial summaries.
#
# This is a simple teaching example. For production files with complex
# quoted text, embedded newlines or special CSV rules, use a robust
# chunk-capable import tool and test its parsing behaviour.

cat("\nStarting chunk-based processing demonstration...\n")

chunk_file <- "data/synthetic_adlb.csv"
chunk_size <- 100000

file_connection <- file(chunk_file, open = "r")

# Read the column names once.
csv_header <- readLines(
  file_connection,
  n = 1,
  warn = FALSE
)

# Store partial summaries from each chunk.
chunk_summaries <- list()
chunk_number <- 0

repeat {

  # Read the next group of data lines.
  chunk_lines <- readLines(
    file_connection,
    n = chunk_size,
    warn = FALSE
  )

  # Stop when no more records are available.
  if (length(chunk_lines) == 0) {
    break
  }

  chunk_number <- chunk_number + 1

  # Re-create a small CSV text block with the original header.
  chunk_text <- paste(
    c(csv_header, chunk_lines),
    collapse = "\n"
  )

  # Read only this chunk into R.
  chunk_data <- read.csv(
    text = chunk_text,
    stringsAsFactors = FALSE
  )

  # Calculate partial count and sum by PARAMCD.
  partial_summary <- aggregate(
    AVAL ~ PARAMCD,
    data = chunk_data,
    FUN = function(x) sum(x, na.rm = TRUE)
  )

  partial_count <- aggregate(
    AVAL ~ PARAMCD,
    data = chunk_data,
    FUN = function(x) sum(!is.na(x))
  )

  names(partial_summary)[2] <- "SUM_AVAL"
  names(partial_count)[2] <- "N_RECORDS"

  partial_result <- merge(
    partial_summary,
    partial_count,
    by = "PARAMCD"
  )

  chunk_summaries[[chunk_number]] <- partial_result

  # Remove chunk-level objects before reading the next chunk.
  rm(chunk_data, partial_summary, partial_count, partial_result)

  if (chunk_number %% 2 == 0) {
    cat("Processed chunks:", chunk_number, "\n")
  }

  gc(verbose = FALSE)
}

close(file_connection)

# Combine partial results from all chunks.
all_partial_results <- do.call(
  rbind,
  chunk_summaries
)

chunk_summary <- aggregate(
  cbind(SUM_AVAL, N_RECORDS) ~ PARAMCD,
  data = all_partial_results,
  FUN = sum
)

chunk_summary$MEAN_AVAL <- (
  chunk_summary$SUM_AVAL / chunk_summary$N_RECORDS
)

chunk_summary <- chunk_summary[
  order(chunk_summary$PARAMCD),
]

write.csv(
  chunk_summary,
  "results/chunk_processing_summary.csv",
  row.names = FALSE
)

cat("\nChunk processing completed. Number of chunks:")
cat(chunk_number, "\n")


# =============================================================================
# SECTION 5: COMPARE RESULTS AND VALIDATE
# Corresponds to: 05_compare_results.R
# =============================================================================

cat("\nSECTION 5: COMPARE AND VALIDATE RESULTS\n")

# We compare the chunk-based summary with a summary calculated
# using the complete ADLB dataset.
#
# The two methods should produce the same counts and means.

full_summary <- aggregate(
  AVAL ~ PARAMCD,
  data = adlb,
  FUN = function(x) {
    mean(x, na.rm = TRUE)
  }
)

names(full_summary)[2] <- "MEAN_AVAL"

full_count <- aggregate(
  AVAL ~ PARAMCD,
  data = adlb,
  FUN = function(x) {
    sum(!is.na(x))
  }
)

names(full_count)[2] <- "N_RECORDS"

full_summary <- merge(
  full_summary,
  full_count,
  by = "PARAMCD"
)

full_summary <- full_summary[
  order(full_summary$PARAMCD),
]

# Put columns in the same order for comparison.
full_summary <- full_summary[
  ,
  c("PARAMCD", "N_RECORDS", "MEAN_AVAL")
]

chunk_summary_check <- chunk_summary[
  ,
  c("PARAMCD", "N_RECORDS", "MEAN_AVAL")
]

chunk_summary_check <- chunk_summary_check[
  order(chunk_summary_check$PARAMCD),
]

# Check row counts and numerical results.
same_parameters <- identical(
  full_summary$PARAMCD,
  chunk_summary_check$PARAMCD
)

same_counts <- identical(
  as.integer(full_summary$N_RECORDS),
  as.integer(chunk_summary_check$N_RECORDS)
)

same_means <- isTRUE(
  all.equal(
    full_summary$MEAN_AVAL,
    chunk_summary_check$MEAN_AVAL,
    tolerance = 1e-8
  )
)

validation_summary <- data.frame(
  CHECK = c(
    "Parameter codes match",
    "Record counts match",
    "Mean values match"
  ),
  RESULT = c(
    same_parameters,
    same_counts,
    same_means
  ),
  STATUS = ifelse(
    c(same_parameters, same_counts, same_means),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)

print(validation_summary)

write.csv(
  validation_summary,
  "results/validation_results.csv",
  row.names = FALSE
)

# Stop the script if the chunked result does not match the full-data result.
stopifnot(
  same_parameters,
  same_counts,
  same_means
)

cat("\nAll validation checks passed.\n")

# ---------------------------------------------------------------------------
# 5.1 Create a simple memory comparison report
# ---------------------------------------------------------------------------

# These figures compare the approximate sizes of selected R objects.
# They are not measurements of total R process memory.

memory_comparison <- data.frame(
  OBJECT = c(
    "ADSL data frame",
    "ADLB data frame",
    "ADLB selected columns",
    "ADSL data.table with AGE_CATEGORY"
  ),
  SIZE_MB = round(
    c(
      as.numeric(object.size(adsl)) / (1024^2),
      as.numeric(object.size(adlb)) / (1024^2),
      as.numeric(object.size(adlb_selected)) / (1024^2),
      as.numeric(object.size(adsl_dt)) / (1024^2)
    ),
    2
  ),
  stringsAsFactors = FALSE
)

print(memory_comparison)

write.csv(
  memory_comparison,
  "results/memory_comparison.csv",
  row.names = FALSE
)

# Save the full-data summary for review.
write.csv(
  full_summary,
  "results/full_data_summary.csv",
  row.names = FALSE
)

# Save the chunk-based summary for review.
write.csv(
  chunk_summary_check,
  "results/chunk_data_summary.csv",
  row.names = FALSE
)


# =============================================================================
# SECTION 6: CREATE A SHORT TASK REPORT
# =============================================================================

report_lines <- c(
  "TASK 25: ASSESS MEMORY USAGE FOR LARGE DATASETS",
  "================================================",
  "",
  paste("Date:", as.character(Sys.Date())),
  paste("R version:", R.version.string),
  paste("ADSL subjects:", nrow(adsl)),
  paste("ADLB laboratory records:", nrow(adlb)),
  "",
  "MEMORY REVIEW",
  "-------------",
  capture.output(print(memory_comparison)),
  "",
  "OBJECT SIZE REVIEW",
  "------------------",
  capture.output(print(object_size_summary)),
  "",
  "CHUNK PROCESSING VALIDATION",
  "---------------------------",
  capture.output(print(validation_summary)),
  "",
  "TECHNIQUES DEMONSTRATED",
  "----------------------",
  "1. Reviewed object sizes using object.size().",
  "2. Reviewed R session memory using gc().",
  "3. Demonstrated copy-on-modify behaviour with a small data frame.",
  "4. Selected only required columns from a large dataset.",
  "5. Used data.table := for reference modification.",
  "6. Removed objects that were no longer required.",
  "7. Read and processed a CSV file in chunks.",
  "8. Compared chunk-based results with full-data results.",
  "",
  "IMPORTANT NOTES",
  "---------------",
  "1. All datasets are synthetic training data.",
  "2. object.size() is an approximate object-size measure.",
  "3. Memory behaviour can differ by R version and operation.",
  "4. Chunk processing is useful when the full file is too large to load comfortably.",
  "5. Always validate that optimized results match the expected results.",
  "6. Do not choose an approach only because it appears to use less memory.",
  "7. Review team standards before applying changes to production clinical programs."
)

writeLines(
  report_lines,
  "documentation/task25_memory_report.txt"
)


# =============================================================================
# SECTION 7: FINAL OUTPUT INVENTORY
# =============================================================================

# List files created in the project folders.
output_inventory <- list.files(
  path = ".",
  recursive = TRUE,
  full.names = FALSE
)

writeLines(
  output_inventory,
  "results/output_inventory.txt"
)

cat("\n")
cat("============================================================\n")
cat("TASK 25 EXECUTION COMPLETED\n")
cat("============================================================\n")

cat("\nFinal garbage collection information:\n")
print(gc())