###############################################################################
## Build the dataset for the post
###############################################################################

## load the packages
library(plyr)

## bring in the network datasets
load("~/Dropbox/Datasets/HigherEd/Cappex-April2014/parsed-data.Rdata")

## cleanup
competitors$comp = gsub("/colleges/", "", competitors$comp)
competitors$comp = gsub("/", "", competitors$comp)
competitors$comp = gsub("-", " ", competitors$comp)


## create the network (inner join where the school names match)
meta$unitid = NULL
meta$admurl.admurl =  NULL
network = merge(competitors, meta, 
                by.x = "comp",
                by.y = "school")
network = subset(network, select = c(unitid, admurl.unitid, rank))
names(network) = c("from", "to", "rank")
rm(meta)

## ensure the from/to is unique, and take the smallest rank
network = ddply(network, .(from, to), summarise, rank = min(rank))
gc()


## we want to download the most current survey 
URL = "http://nces.ed.gov/ipeds/datacenter/data/HD2012.zip"
# download.file(URL, destfile = "hd.zip")
# unzip("hd.zip")

## bring in the csv file
FILE = list.files(pattern = "csv$")
hd = read.csv(FILE)
colnames(hd) = tolower(colnames(hd))

## filter to the population of schools we want, including lat/long coordinates
hd = subset(hd, sector %in% c(1, 2))
hd = subset(hd, obereg %in% c(1:8))
hd = subset(hd, pset4flg == 1)
hd = subset(hd, !is.na(longitud) & !is.na(latitude))


## keep only lower 48 for visualization purposes
STATES = state.abb
STATES = STATES[which(!STATES %in% c('AK','HI') )]
hd = subset(hd, stabbr %in% STATES)
rm(STATES)

## this is a subjective filter
hd = subset(hd, carnegie %in% c(15:32))

## what are the unitids
ids = hd$unitid

## make sure that both schools in the graph are in the IPEDS dataset
network = subset(network, from %in% ids & to %in% ids)


## keep only the variables necessary for this analysis, but retains all rows
hd_tmp = subset(hd, select = c(unitid, longitud,latitude ))

## merge on the lat/long pairs for each school
network = merge(network, hd_tmp, by.x="from", by.y="unitid")
names(network)[4] = "from_long"
names(network)[5] = "from_lat"
network = merge(network, hd_tmp, by.x="to", by.y="unitid")
names(network)[6] = "to_long"
names(network)[7] = "to_lat"

## look at the first few rows
head(network, 10)