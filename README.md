# Million Songs Dataset statistical analysis
This is the manifestation of a project in "Applied Statistics" for 3rd year students at the [Faculty of Mathematics and Informatics](http://fmi.uni-sofia.bg/) of Sofia University.
Our main goal here will be to process some subset of the million songs dataset and extract meaningful correlations between the parameters.

## LaTeX and project presentation/documentation
You can find documentation for the project as LaTeX scripts and PDFs in the "Project Documentation" subfolder.

## Preparing the dataset

The [million songs dataset](https://labrosa.ee.columbia.edu/millionsong/) is in the exotic HDF5 format. It contains a lot of "local" file information (song segments, tempos and audio characteristics for each segment, etc). They could thus be used for audio recognition and song segment recognition. Here, however, we will focus on more global characteristics of the songs. We will be investigating *Album*, *Artist* and *Song* details like release year, tempo, popularity (refered to as "hotness" in the dataset), loudness, etc. to produce a CSV that is edible by R, we needed to create a script, which can be found [here](https://github.com/nikox94/Million-Song-Dataset-HDF5-to-CSV). This extracts the attributes we need from the HDF5 file and converts them to CSV. We have a sample dataset of a 1% subset of the million songs, i.e. we have 10,000 songs in the sample dataset. It is about 2MB and can easily be worked with to produce prototypes, which can then be run on the complete dataset if tractable. To get the whole 1,000,000 songs as a CSV, an Amazon machine was launched, with the dataset (280GB) attached as an Amazon EBS Volume (Amazon supports Million Songs as a public dataset and has an available copy for mounting). This was all run in the cloud, with our script currently running through the whole dataset, extracting the data we need. The resulting CSV should be 200MB and the total running time of the extraction should be 30 hours. The used EBS volume is an SSD, but we seem to be reaching some other bottleneck (CPU usage, RAM, SSD iops all look fine). My suspicion is that the bottleneck is that the Amazon Volume is actually created on the fly as data from the Amazon Snapshot is being read.

## Installation
You need to have some form of R installed in order to work with the dataset. We will provide sample scripts for manipulating the data and plotting.

	# Installing R under Ubuntu-based Linux
	sudo apt install r-base
	# Check version
	R --version
	# We are using 3.2.3 for this project

## Cleaning the data
Before we start work on the data in R, we used LibreOffice Calc, to reorder some columns and remove some other columns.

Let's first open the dataset in R and look at its statistics to decide if some columns should be amputated.

	> D <- read.csv(file="dataset-large.csv", header=T)
	> str(D)
	'data.frame':	291546 obs. of  21 variables:
	 $ SongNumber             : num  1 2 3 4 5 6 7 8 9 10 ...
	 $ SongID                 : Factor w/ 291295 levels "","0.0","1","3",..: 263496 152632 213560 48668 42557 93625 72511 62128 97215 113503 ...
	 $ AlbumID                : num  38594 160575 308005 195821 599348 ...
	 $ AlbumName              : Factor w/ 107444 levels "!","?","????????? ????",..: 91972 19091 84392 53311 28758 48087 56529 39140 99253 4967 ...
	 $ ArtistID               : Factor w/ 37638 levels "0","0.0","-10.39",..: 13382 25154 24256 5472 15107 11452 794 6227 36138 4220 ...
	 $ ArtistLatitude         : num  7.37 47.04 NA 43.74 35.15 ...
	 $ ArtistLocation         : Factor w/ 4567 levels ""," ","0.0","0121 UK",..: 712 3014 4392 2553 2507 1 1 2027 2866 1 ...
	 $ ArtistLongitude        : num  12.3 -122.9 NA -84.6 -90 ...
	 $ ArtistName             : Factor w/ 48670 levels "","!!!","0.0",..: 3620 42276 21027 4906 28095 23964 28565 30756 30656 46103 ...
	 $ Danceability           : Factor w/ 261 levels "","0","0.0","-10.02",..: 3 3 3 3 3 3 3 3 3 3 ...
	 $ Duration               : num  368 176 255 233 111 ...
	 $ Energy                 : Factor w/ 226 levels "","0.0","102.348",..: 2 2 2 2 2 2 2 2 2 2 ...
	 $ KeySignature           : num  9 5 7 9 5 9 2 4 3 11 ...
	 $ KeySignatureConfidence : Factor w/ 1019 levels "","0.0","0.001",..: 590 597 102 785 671 593 358 552 172 219 ...
	 $ Loudness               : Factor w/ 26713 levels "","0.0","0.006",..: 1699 5538 21177 22475 10679 3276 23705 21901 24611 20564 ...
	 $ Hotness                : Factor w/ 36208 levels "","0","0.0","0.187648445991",..: 10058 9107 27400 36208 36208 36208 7150 36208 27182 30269 ...
	 $ Tempo                  : num  139.1 87.7 87.9 98 201 ...
	 $ TimeSignature          : Factor w/ 12 levels "","0","1","10",..: 6 6 6 6 3 3 6 6 7 6 ...
	 $ TimeSignatureConfidence: num  0 0.769 0.895 0.624 0 0.147 1 0 0.278 1 ...
	 $ Title                  : Factor w/ 235833 levels "","~-","_","-",..: 101831 193488 97839 70893 16104 5800 24395 147670 56779 74282 ...
	 $ Year                   : Factor w/ 240 levels "","0","0.0","0.246865094453",..: 83 81 94 2 2 2 87 89 96 94 ...

As we can see, SongID and AlbumId will play no significant role in our calculations, also ArtistID does not matter. We can remove them using

	> D$SongID <- NULL
	> D$AlbumID <- NULL
	> D$ArtistID <- NULL

Let's check some more: the data distribution and any fields that have an overwhelming amount of 'NAs'

	> nrow(D)
	[1] 291546

We see that we have about 300 000 rows, however in LibreOffice Calc we know we should have ~ 500 000. If we look carefully when reading the data, there was an error. We will reread the data now to fix this. After some experimentation, this seems to work:
	
	> D <- read.csv("dataset-large.csv", quote = "", header=T)
	> nrow(D)
	[1] 570064
	
We reapply the transformations as above and we continue with our summary analysis.

	> summary(D)
	   SongNumber                         AlbumName      ArtistLatitude  
	 Min.   :     1   "Greatest Hits"          :  1157   Min.   :-53.1   
	 1st Qu.:142517   "Live"                   :   656   1st Qu.: 34.1   
	 Median :285032   "The Collection"         :   489   Median : 40.7   
	 Mean   :285032   "The Ultimate Collection":   451   Mean   : 39.0   
	 3rd Qu.:427548   "The Very Best Of"       :   423   3rd Qu.: 47.6   
	 Max.   :570064   "The Best Of"            :   361   Max.   : 70.7   
			  (Other)                  :566527   NA's   :366508  
		   ArtistLocation   ArtistLongitude              ArtistName    
	 ""               :277836   Min.   :-162.4   "Joan Baez"      :   114  
	 "London England" :  7430   1st Qu.: -91.5   "Michael Jackson":   114  
	 "New York NY"    :  7268   Median : -77.4   "Johnny Cash"    :   109  
	 "Los Angeles CA" :  6843   Mean   : -58.4   "Beastie Boys"   :   106  
	 "California - LA":  4903   3rd Qu.:  -2.2   "Neil Diamond"   :   104  
	 "Chicago IL"     :  4745   Max.   : 175.5   "Duran Duran"    :   103  
	 (Other)          :261039   NA's   :366508   (Other)          :569414  
	  Danceability    Duration            Energy   KeySignature   
	 Min.   :0     Min.   :   0.313   Min.   :0   Min.   : 0.000  
	 1st Qu.:0     1st Qu.: 180.715   1st Qu.:0   1st Qu.: 2.000  
	 Median :0     Median : 228.754   Median :0   Median : 5.000  
	 Mean   :0     Mean   : 249.235   Mean   :0   Mean   : 5.322  
	 3rd Qu.:0     3rd Qu.: 289.573   3rd Qu.:0   3rd Qu.: 9.000  
	 Max.   :0     Max.   :3034.906   Max.   :0   Max.   :11.000  
								      
	 KeySignatureConfidence    Loudness          Hotness           Tempo       
	 Min.   :0.0000         Min.   :-57.871   Min.   :0.00     Min.   :  0.00  
	 1st Qu.:0.2130         1st Qu.:-12.671   1st Qu.:0.22     1st Qu.: 97.98  
	 Median :0.4620         Median : -8.960   Median :0.38     Median :122.10  
	 Mean   :0.4425         Mean   :-10.122   Mean   :0.36     Mean   :123.88  
	 3rd Qu.:0.6520         3rd Qu.: -6.379   3rd Qu.:0.53     3rd Qu.:144.12  
	 Max.   :1.0000         Max.   :  4.318   Max.   :1.00     Max.   :296.47  
						  NA's   :239057                   
	 TimeSignature   TimeSignatureConfidence            Title             Year     
	 Min.   :0.000   Min.   :0.000           "Intro"       :   873   Min.   :   0  
	 1st Qu.:3.000   1st Qu.:0.126           "Untitled"    :   251   1st Qu.:   0  
	 Median :4.000   Median :0.557           "Outro"       :   210   Median :1969  
	 Mean   :3.594   Mean   :0.516           "Interlude"   :   161   Mean   :1029  
	 3rd Qu.:4.000   3rd Qu.:0.869           "Home"        :   141   3rd Qu.:2002  
	 Max.   :7.000   Max.   :1.000           "Silent Night":   126   Max.   :2011  
						 (Other)       :568302              

It is evident that we have a problem with the *Danceability* and *Energy* values, which seems to be 0 for almost all observations. Let's remove them.

	> D$Danceability <- NULL
	> D$Energy <- NULL

Let's look at the data structure again

	> str(D)
	'data.frame':	570064 obs. of  16 variables:
	 $ SongNumber             : int  1 2 3 4 5 6 7 8 9 10 ...
	 $ AlbumName              : Factor w/ 131440 levels "\"!\"","\"????????? ????\"",..: 112621 23324 103367 65260 35104 58920 69227 47832 121390 6061 ...
	 $ ArtistLatitude         : num  7.37 47.04 NA 43.74 35.15 ...
	 $ ArtistLocation         : Factor w/ 4743 levels "\" \"","\"\"",..: 721 3123 4559 2640 2594 2 2 2091 2963 2 ...
	 $ ArtistLongitude        : num  12.3 -122.9 NA -84.6 -90 ...
	 $ ArtistName             : Factor w/ 59728 levels "\"!!!\"","\"0131\"",..: 4222 51936 25721 5822 34485 29383 35066 37805 37674 56520 ...
	 $ Duration               : num  368 176 255 233 111 ...
	 $ KeySignature           : int  9 5 7 9 5 9 2 4 3 11 ...
	 $ KeySignatureConfidence : num  0.588 0.595 0.1 0.783 0.669 0.591 0.356 0.55 0.17 0.217 ...
	 $ Loudness               : num  -11.48 -15.19 -4.71 -5.97 -20.1 ...
	 $ Hotness                : num  0.355 0.311 0.693 NaN NaN ...
	 $ Tempo                  : num  139.1 87.7 87.9 98 201 ...
	 $ TimeSignature          : int  4 4 4 4 1 1 4 4 5 4 ...
	 $ TimeSignatureConfidence: num  0 0.769 0.895 0.624 0 0.147 1 0 0.278 1 ...
	 $ Title                  : Factor w/ 429675 levels "\"~-\"","\"<...^...>\"",..: 185849 352368 178516 129826 29594 10777 44838 269199 104004 135888 ...
	 $ Year                   : int  1995 1993 2006 0 0 0 1999 2001 2008 2006 ...

AlbumName, ArtistName should be character fields, not factors. KeySignature is a Factor, not an int. Same goes for TimeSignature. Title should be a character string, not a factor. Year should be a factor, not an int. We should also split years into buckets (year-periods) for better factor distribution through the data.
	
	> D$AlbumName <- as.character(D$AlbumName)
	> D$ArtistName <- as.character(D$ArtistName)
	> D$Title <- as.character(D$Title)
	> D$KeySignature <- as.factor(D$KeySignature)
	> D$TimeSignature <- as.factor(D$TimeSignature)
	
For the year factor, we might need some more information. We want to make the buckets relatively balanced. We will be using the *cut* function to make the bins. It can accept either a vector of pre-defined cut-points, or a number that it then uses to convert the data into n buckets. Let's try the second approach:

	> k <- cut(D$Year, breaks=10)
	> str(k)
	 Factor w/ 10 levels "(-2.01,201]",..: 10 10 10 1 1 1 10 10 10 10 ...
	> summary(k)
		(-2.01,201]           (201,402]           (402,603]           (603,804] 
		     276500                   0                   0                   0 
	     (804,1.01e+03] (1.01e+03,1.21e+03] (1.21e+03,1.41e+03] (1.41e+03,1.61e+03] 
			  0                   0                   0                   0 
	(1.61e+03,1.81e+03] (1.81e+03,2.01e+03] 
			  0              293564 

It seems that the breaks are not very even. We will need to specify the breaks by hand.

	> summary(as.factor(D$Year))
	     0   1922   1924   1925   1926   1927   1928   1929   1930   1931   1932 
	276500      3      4      5     12     21     29     54     21     20      5 
	  1933   1934   1935   1936   1937   1938   1939   1940   1941   1942   1943 
	     5     12     13      9     16      8     28     28     19     13      7 
	  1944   1945   1946   1947   1948   1949   1950   1951   1952   1953   1954 
	     9     19     14     29     22     34     47     42     41     90     68 
	  1955   1956   1957   1958   1959   1960   1961   1962   1963   1964   1965 
	   167    293    335    328    326    222    316    345    503    507    635 
	  1966   1967   1968   1969   1970   1971   1972   1973   1974   1975   1976 
	   803   1015   1031   1284   1364   1251   1279   1499   1247   1431   1233 
	  1977   1978   1979   1980   1981   1982   1983   1984   1985   1986   1987 
	  1444   1631   1787   1779   1801   2036   1965   1940   2009   2424   2897 
	  1988   1989   1990   1991   1992   1993   1994   1995   1996   1997   1998 
	  3216   3729   4112   4907   5483   5917   6855   7511   8032   8619   8992 
	  1999   2000   2001   2002   2003   2004   2005   2006   2007   2008   2009 
	 10598  10913  12386  13233  15521  16990  20111  21477  22385  19715  17645 
	  2010   2011 
	  5342      1 

As we can see the data is fairly balanced in its distribution. We could group all songs before 1950 into one bucket, use steps of 5 for 1950-1970, then steps of 2 for 1970-1990 and then a step of 1. We can have something like this

	> k <- cut(D$Year, breaks=c(-1, seq(1950, 1965, 5), seq(1970, 1989, 2), seq(1990, 2009, 1), 2011), ordered_result=T)
	> str(k)
	 Ord.factor w/ 35 levels "(-1,1950]"<"(1950,1955]"<..: 20 18 31 1 1 1 24 26 33 31 ...
	> summary(k)
	  (-1,1950] (1950,1955] (1955,1960] (1960,1965] (1965,1970] (1970,1972] 
	     277006         408        1504        2306        5497        2530 
	(1972,1974] (1974,1976] (1976,1978] (1978,1980] (1980,1982] (1982,1984] 
	       2746        2664        3075        3566        3837        3905 
	(1984,1986] (1986,1988] (1988,1990] (1990,1991] (1991,1992] (1992,1993] 
	       4433        6113        7841        4907        5483        5917 
	(1993,1994] (1994,1995] (1995,1996] (1996,1997] (1997,1998] (1998,1999] 
	       6855        7511        8032        8619        8992       10598 
	(1999,2000] (2000,2001] (2001,2002] (2002,2003] (2003,2004] (2004,2005] 
	      10913       12386       13233       15521       16990       20111 
	(2005,2006] (2006,2007] (2007,2008] (2008,2009] (2009,2011] 
	      21477       22385       19715       17645        5343 

This is much better.
Let's save it

	> D$YearBucket <- cut(D$Year, breaks=c(-1, seq(1950, 1965, 5), seq(1970, 1989, 2), seq(1990, 2009, 1), 2011), ordered_result=T)

Let's save our dataframe object.

	> saveRDS(D, "dataset-large.rds")

Great! Now we are ready to continue with our data exploration.

## Setting up for data exploration
To load the sample data subset do the following in an R console, with the "R" folder of this project being the working directory of R.

	Some code in R
	Including read.csv(.... headers=true, ....)
	.......

And the we could do some regressions on this. But first, let's do some sample statistics on the data.

	//To be continued
