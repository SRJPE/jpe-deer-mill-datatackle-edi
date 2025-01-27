library(EDIutils)
library(tidyverse)
library(EMLaide)
library(readxl)
library(EML)

datatable_metadata <-
  dplyr::tibble(filepath = c("data/catch.csv",
                             "data/recapture.csv",
                             "data/release.csv",
                             "data/trap.csv",
                             "data/environmental.csv"),
                attribute_info = c("metadata/catch_metadata.xlsx",
                                   "metadata/recapture_metadata.xlsx",
                                   "metadata/release_metadata.xlsx",
                                   "metadata/trap_visit_metadata.xlsx",
                                   "metadata/trap_visit_environmental_metadata.xlsx"),
                datatable_description = c("Catch data from Deer and Mill creeks",
                                          "Recapture data from Deer and Mill creeks",
                                          "Release data from Deer and Mill creeks",
                                          "Trap visit data from Deer and Mill creeks",
                                          "Environmental data from Deer and Mill creeks"),
                datatable_url = paste0("https://raw.githubusercontent.com/SRJPE/jpe-deer-mill-datatackle-edi/main/data/",
                                       c("catch.csv",
                                         "recapture.csv",
                                         "release.csv",
                                         "trap.csv",
                                         "environmental.csv")))

# save cleaned data to `data/`
excel_path <- "metadata/deer_mill_metadata.xlsx" 
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "metadata/abstract.docx"
methods_docx <- "metadata/methods.md"

#edi_number <- reserve_edi_id(user_id = Sys.getenv("EDI_USER_ID"), password = Sys.getenv("EDI_PASSWORD"))
edi_number <- "edi.1775.1" 

dataset <- list() %>%
  add_pub_date() %>%
  add_title(metadata$title) %>%
  add_personnel(metadata$personnel) %>%
  add_keyword_set(metadata$keyword_set) %>%
  add_abstract(abstract_docx) %>%
  add_license(metadata$license) %>%
  add_method(methods_docx) %>%
  add_maintenance(metadata$maintenance) %>%
  add_project(metadata$funding) %>%
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) %>%
  add_datatable(datatable_metadata) 
  # add_other_entity(other_entity_metadata_1)

# GO through and check on all units
custom_units <- data.frame(id = c(rep("fish", 6), rep("revolutions per minute",2), "described in measure_unit field"),
                           unitType = c(rep("dimensionless", 9)),
                           parentSI = c(rep(NA, 9)),
                           multiplierToSI = c(rep(NA, 9)),
                           description = c(rep("number of fish counted",6), rep("number of revolutions trap makes in one minute",2),"units are described in the measure_unit field"))


unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = edi_number,
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(unitList = unitList))
)
edi_number
EML::write_eml(eml, paste0(edi_number, ".xml"))
EML::eml_validate(paste0(edi_number, ".xml"))

# EMLaide::evaluate_edi_package(user_id = Sys.getenv("EDI_USER_ID"),
#                                           password = Sys.getenv("EDI_PASSWORD"),
#                                           eml_file_path = "edi/edi.1775.1.xml",
#                                           environment = "staging")
#
# EMLaide::upload_edi_package(user_id = Sys.getenv("EDI_USER_ID"),
#                             password = Sys.getenv("EDI_PASSWORD"),
#                             eml_file_path = "edi.1775.1.xml",
#                             environment = "production")
