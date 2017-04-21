#!/usr/bin/Rscript

prepare <- function(D) {
	D$SongID <- NULL
	D$AlbumID <- NULL
	D$ArtistID <- NULL
	D$Danceability <- NULL
	D$Energy <- NULL
	D$AlbumName <- as.character(D$AlbumName)
	D$ArtistName <- as.character(D$ArtistName)
	D$Title <- as.character(D$Title)
	D$KeySignature <- as.factor(D$KeySignature)
	D$TimeSignature <- as.factor(D$TimeSignature)
	D$YearBucket <- cut(D$Year, breaks=c(-1, seq(1950, 1965, 5), seq(1970, 1989, 2), seq(1990, 2009, 1), 2011), ordered_result=F)
	return(D)
}

D <- read.csv("dataset-small.csv", quote = "", header=T)
nrow(D)
cat(str(D))
cat("Transforming D\n\n")
D = prepare(D)
cat(str(D))
