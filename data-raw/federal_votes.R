
# The source data is scattered across several URLs
# Construct a list and then pull one at a time, depending on needs
sources <- list(year = c(2006, 2008, 2011, 2015, 2019),
                election =c(39, 40, 41, 42, 43),
                url = c("http://www.elections.ca/scripts/OVR2006/25/data_donnees/pollresults_resultatsbureau_canada.zip",
                        "http://www.elections.ca/scripts/OVR2008/31/data/pollresults_resultatsbureau_canada.zip",
                        "http://www.elections.ca/scripts/OVR2011/34/data_donnees/pollresults_resultatsbureau_canada.zip",
                        "https://www.elections.ca/res/rep/off/ovr2015app/41/data_donnees/pollresults_resultatsbureauCanada.zip",
                        "https://www.elections.ca/res/rep/off/ovr2019app/51/data_donnees/pollresults_resultatsbureauCanada.zip")
)
zip_file <- "data-raw/pollresults_resultatsbureau_canada.zip"

get_results <- function(this_source = 5) {
  if(!file.exists(zip_file)) { # Only download the data once
    download.file(sources$url[[this_source]],
                  destfile = zip_file)
    unzip(zip_file, exdir=paste("data-raw", "pollresults", sep = "/")) # Extract the data into data-raw
  }
  results_files <- list.files(path = "data-raw/pollresults",
                              pattern = "pollresults_resultatsbureau[[:digit:]]{5}.csv",
                              full.names = TRUE)
  results <- do.call("rbind", lapply(results_files, function(.file){readr::read_csv(.file)}))

  # Encoding changes across files
  names(results) <- iconv(names(results),"WINDOWS-1252","UTF-8")
  # Header names change slightly across years, these work, so far
  results <- dplyr::select(results, contains("Family"), contains("First"),
                           contains("Votes"), matches("Affiliation.*English"),
                           contains("District Number"), contains("Polling Station Number"), contains("Incumbent"))
  names(results) <- c("last", "first", "votes", "party", "district", "poll", "incumbent")
  results <- dplyr::transmute(results,
                              candidate = as.factor(stringr::str_c(results$last,
                                                                   results$first ,
                                                                   sep = " ")),
                              year = as.factor(sources$year[[this_source]]),
                              election_num = as.factor(sources$election[[this_source]]),
                              type = "federal",
                              votes = as.integer(results$votes),
                              party = as.factor(results$party),
                              district = as.character(results$district),
                              poll = as.character(results$poll),
                              incumbent = as.logical(ifelse(results$incumbent == "Y", 1, 0))
  )
  file.remove(zip_file)
  results
}

federal_results <- get_results(this_source = 4)
federal_results <- get_results(this_source = 5)
federal_results <- dplyr::bind_rows(federal_results,
                                    get_results(this_source = 4),
                                    get_results(this_source = 3),
                                    get_results(this_source = 2),
                                    get_results(this_source = 1))



usethis::use_data(DATASET, overwrite = TRUE)
