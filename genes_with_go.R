#!/usr/bin/env Rscript
args = commandArgs(trailingOnly = TRUE)

usage <- "Usage: genes_with_go.R GO_terms
example: Rscript --vanilla genes_with_go.R GO:0006338 "

# Check if biomaRt installed. TODO: If not - install. 
stopifnot("biomaRt" %in% installed.packages())

if (length(args) == 0) {
  stop("At least one GO ID must be supplied")
}

library(biomaRt)

if (!all(grepl("GO:", args))) {
  stop(paste("Bad formatting of GO terms.", 
             usage, sep = "\n"))
}

gos <- args

ensembl <- useMart("ensembl",
                  dataset = "hsapiens_gene_ensembl") 

atrs <- c("ensembl_gene_id", "external_gene_name", 
          "hgnc_symbol", "description", "go_id", "name_1006")
atrs_in_mart <- atrs %in% listAttributes(mart = ensembl)$name

if(!all(atrs_in_mart)) {
  stop(paste0("Following attributes not found in mart: ", 
              paste(atrs[!atrs_in_mart], collapse = ", ")))
}

fltrs <- c("go")
fltrs_in_mart <- fltrs %in% listFilters(mart = ensembl)$name
if(!all(fltrs_in_mart)) {
  stop(paste0("Following filters not found in mart: ", 
              paste(fltrs[!fltrs_in_mart], collapse = ", ")))
}


genes <- getBM(attributes = atrs, 
               filters = fltrs, 
               values = gos, 
               mart = ensembl)

genes <- genes[genes$go_id %in% gos, ]

write.table(genes, 
            file = "", 
            sep = "\t",
            quote = FALSE, 
            row.names = FALSE)
