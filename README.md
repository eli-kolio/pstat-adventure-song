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

## Hotness Linear model

We want to predict the hotness of a song based on its other characteristics. Let's try doing that. First let's load the dataset

	> D <- readRDS("dataset-large.rds")

Now looking at the structure of the dataset (`str(D)`), we will want to identify the candidate variables to use in a regression. If we just use

	linear_model1 = lm(Hotness ~ . , data=D)

This crashed my computer because of using too much RAM. Why? Because the YearBucket and ArtistLocation and KeySignature and TimeSignature *factor* variables create an explosion of "regression input vars", because each factor value is converted into a boolean regression input variable which causes too much memory to be used. Thus we should limit ourselves to a few, well-chosen variables here. Let us try:

	> lm1 <- lm(Hotness ~ Duration + ArtistLatitude + ArtistLongitude + KeySignature + Loudness + Tempo + TimeSignature, data=D)
	> summary(lm1)


	Call:
	lm(formula = Hotness ~ Duration + ArtistLatitude + ArtistLongitude + 
	    KeySignature + Loudness + Tempo + TimeSignature, data = D)

	Residuals:
	     Min       1Q   Median       3Q      Max 
	-0.46710 -0.14701  0.02158  0.17243  0.74014 

	Coefficients:
			  Estimate Std. Error t value Pr(>|t|)    
	(Intercept)      3.309e-01  3.206e-02  10.320  < 2e-16 ***
	Duration        -1.428e-05  5.706e-06  -2.502 0.012354 *  
	ArtistLatitude   1.036e-03  4.254e-05  24.344  < 2e-16 ***
	ArtistLongitude  2.210e-04  1.191e-05  18.554  < 2e-16 ***
	KeySignature1    1.311e-02  3.022e-03   4.339 1.43e-05 ***
	KeySignature2    5.492e-03  2.695e-03   2.037 0.041603 *  
	KeySignature3    4.586e-03  4.215e-03   1.088 0.276546    
	KeySignature4    1.275e-02  2.943e-03   4.332 1.48e-05 ***
	KeySignature5   -1.768e-03  3.034e-03  -0.583 0.559995    
	KeySignature6    1.569e-02  3.340e-03   4.698 2.63e-06 ***
	KeySignature7   -2.394e-03  2.628e-03  -0.911 0.362234    
	KeySignature8    1.028e-02  3.469e-03   2.963 0.003048 ** 
	KeySignature9    2.689e-03  2.715e-03   0.990 0.321988    
	KeySignature10  -4.437e-03  3.211e-03  -1.382 0.167097    
	KeySignature11   1.103e-02  3.024e-03   3.647 0.000266 ***
	Loudness         7.766e-03  1.339e-04  58.012  < 2e-16 ***
	Tempo            1.418e-04  1.936e-05   7.321 2.47e-13 ***
	TimeSignature1   5.071e-02  3.191e-02   1.589 0.111982    
	TimeSignature3   5.736e-02  3.189e-02   1.799 0.072070 .  
	TimeSignature4   5.613e-02  3.185e-02   1.762 0.078040 .  
	TimeSignature5   5.763e-02  3.195e-02   1.804 0.071270 .  
	TimeSignature7   6.682e-02  3.212e-02   2.080 0.037484 *  
	---
	Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

	Residual standard error: 0.23 on 120934 degrees of freedom
	  (449108 observations deleted due to missingness)
	Multiple R-squared:  0.04101,	Adjusted R-squared:  0.04084 
	F-statistic: 246.3 on 21 and 120934 DF,  p-value: < 2.2e-16

The R-squared value is very low, which means that the predictive power of the model is not very good. Also we have made a mistake - the ArtistLatitude and ArtistLongtitude variables show as significant however they should not be used in a regression model, since they mean that an artist with larger longitude is "better" or "worse" than one with a smaller one. Such a view is wrong. Latitude and Longitude can be used in decision trees to decide "regions" of popularity. Let's remove them and make a new model.

	> lm2 <- lm(Hotness ~ Duration + KeySignature + Loudness + Tempo + TimeSignature, data=D)
	> summary(lm2)

	Call:
	lm(formula = Hotness ~ Duration + KeySignature + Loudness + Tempo + 
	    TimeSignature, data = D)

	Residuals:
	     Min       1Q   Median       3Q      Max 
	-0.45919 -0.14562  0.02339  0.17274  0.71653 

	Coefficients:
			 Estimate Std. Error t value Pr(>|t|)    
	(Intercept)     4.136e-01  1.884e-02  21.952  < 2e-16 ***
	Duration       -1.679e-05  3.446e-06  -4.873 1.10e-06 ***
	KeySignature1   7.043e-03  1.813e-03   3.884 0.000103 ***
	KeySignature2   2.964e-03  1.659e-03   1.787 0.074018 .  
	KeySignature3   8.871e-03  2.631e-03   3.372 0.000748 ***
	KeySignature4   9.039e-03  1.805e-03   5.009 5.48e-07 ***
	KeySignature5  -5.275e-04  1.894e-03  -0.278 0.780636    
	KeySignature6   1.041e-02  2.013e-03   5.169 2.36e-07 ***
	KeySignature7  -4.136e-03  1.617e-03  -2.558 0.010542 *  
	KeySignature8   1.193e-02  2.127e-03   5.611 2.02e-08 ***
	KeySignature9   6.950e-04  1.667e-03   0.417 0.676826    
	KeySignature10 -5.520e-03  1.958e-03  -2.819 0.004812 ** 
	KeySignature11  2.813e-03  1.817e-03   1.548 0.121573    
	Loudness        7.384e-03  8.391e-05  88.003  < 2e-16 ***
	Tempo           6.887e-05  1.173e-05   5.873 4.29e-09 ***
	TimeSignature1 -2.732e-03  1.880e-02  -0.145 0.884415    
	TimeSignature3  8.096e-03  1.879e-02   0.431 0.666485    
	TimeSignature4  9.250e-03  1.876e-02   0.493 0.622024    
	TimeSignature5  5.217e-03  1.882e-02   0.277 0.781617    
	TimeSignature7  1.327e-02  1.893e-02   0.701 0.483163    
	---
	Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

	Residual standard error: 0.2314 on 330987 degrees of freedom
	  (239057 observations deleted due to missingness)
	Multiple R-squared:  0.02698,	Adjusted R-squared:  0.02692 
	F-statistic:   483 on 19 and 330987 DF,  p-value: < 2.2e-16

Our redsidual standard error has not changed between the models. That means that the data fit is approximately the same. The R-squared is quite low, which means the model is quite weak. We do also observer that the TimeSignature variable is not significant in any of its values. We can remove it. Again

        > lm3 <- lm(Hotness ~ Duration + KeySignature + Loudness + Tempo, data=D)
	> summary(lm3)

	Call:
	lm(formula = Hotness ~ Duration + KeySignature + Loudness + Tempo, 
	    data = D)

	Residuals:
	     Min       1Q   Median       3Q      Max 
	-0.46007 -0.14564  0.02336  0.17271  0.71787 

	Coefficients:
			 Estimate Std. Error t value Pr(>|t|)    
	(Intercept)     4.206e-01  2.284e-03 184.145  < 2e-16 ***
	Duration       -1.323e-05  3.413e-06  -3.877 0.000106 ***
	KeySignature1   7.183e-03  1.813e-03   3.962 7.45e-05 ***
	KeySignature2   2.892e-03  1.659e-03   1.743 0.081421 .  
	KeySignature3   8.987e-03  2.631e-03   3.415 0.000637 ***
	KeySignature4   9.069e-03  1.805e-03   5.025 5.05e-07 ***
	KeySignature5  -5.441e-04  1.894e-03  -0.287 0.773919    
	KeySignature6   1.060e-02  2.013e-03   5.265 1.40e-07 ***
	KeySignature7  -4.106e-03  1.617e-03  -2.539 0.011129 *  
	KeySignature8   1.203e-02  2.127e-03   5.654 1.57e-08 ***
	KeySignature9   5.829e-04  1.668e-03   0.350 0.726694    
	KeySignature10 -5.325e-03  1.958e-03  -2.720 0.006531 ** 
	KeySignature11  2.904e-03  1.817e-03   1.598 0.109987    
	Loudness        7.487e-03  8.231e-05  90.969  < 2e-16 ***
	Tempo           7.283e-05  1.166e-05   6.245 4.23e-10 ***
	---
	Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

	Residual standard error: 0.2314 on 330992 degrees of freedom
	  (239057 observations deleted due to missingness)
	Multiple R-squared:  0.02668,	Adjusted R-squared:  0.02664 
	F-statistic:   648 on 14 and 330992 DF,  p-value: < 2.2e-16

This is the final linear model and the best model that we can produce with just a simple linear regression. Let's try building a decision tree.

	> dtree1 = rpart(Hotness ~ . , data=D)

After about 15 minutes the command has not yet finished. Let's reduce the number of parameters.

	> dtree1 <- rpart(Hotness ~ Duration + ArtistLatitude + ArtistLongitude + KeySignature + Loudness + Tempo + TimeSignature, data=D)
	> rpart.plot(dtree1)
	> summary(dtree1)
	Call:
	rpart(formula = Hotness ~ Duration + ArtistLatitude + ArtistLongitude + 
	    KeySignature + Loudness + Tempo + TimeSignature, data = D)
	  n=331007 (239057 observations deleted due to missingness)

		  CP nsplit rel error   xerror        xstd
	1 0.02306061      0 1.0000000 1.000004 0.001831945
	2 0.01000000      1 0.9769394 0.976951 0.001824626

	Variable importance
	Loudness 
	     100 

	Node number 1: 331007 observations,    complexity param=0.02306061
	  mean=0.3564254, MSE=0.05502616 
	  left son=2 (195953 obs) right son=3 (135054 obs)
	  Primary splits:
	      Loudness        < -7.6195   to the left,  improve=0.023060610, (0 missing)
	      ArtistLatitude  < 40.73422  to the left,  improve=0.003830893, (210051 missing)
	      ArtistLongitude < -73.95689 to the left,  improve=0.002798338, (210051 missing)
	      Duration        < 180.9889  to the left,  improve=0.002209511, (0 missing)
	      TimeSignature   splits as  LLLRLL, improve=0.001912336, (0 missing)

	Node number 2: 195953 observations
	  mean=0.3268522, MSE=0.0534683 

	Node number 3: 135054 observations
	  mean=0.3993338, MSE=0.05417641 

This is the best we can do so far. Loudness was the most significant datum. We could finally try with some random forest models. This is however out of scope of this course at the Faculty of Mathematics and Informatics at Sofia University and we won't go into it. We could however try to cluster the datapoints and run models seperately on the different clusters.

We could look at some plots to better understand the data relationships before moving on.

	> plot(D$Duration, D$Hotness)
	> plot(D$Loudness, D$Hotness)
	> plot(D$Tempo, D$Hotness)
	> hist(D$Hotness)
	> hist(D$Loudness)
	> hist(D$Tempo)


	//TODO: Fix code and add year as a parameter

## Predicting the song year



## Setting up for data exploration
To load the sample data subset do the following in an R console, with the "R" folder of this project being the working directory of R.

	Some code in R
	Including read.csv(.... headers=true, ....)
	.......

And the we could do some regressions on this. But first, let's do some sample statistics on the data.

	//To be continued

## Logistic regression 

To use the logistic regression in R we need to use the glm flunction. For example we did as it follows:

	>glm2<-glm(YearBucket ~ Duration + KeySignature + Loudness + Tempo + TimeSignature, data=D, family=binomial)
	>summary(glm2)
	
		
	Call:
	glm(formula = YearBucket ~ Duration + KeySignature + Loudness + 
		Tempo + TimeSignature, family = binomial, data = D)

	Deviance Residuals: 
	   Min      1Q  Median      3Q     Max  
	-1.478  -1.206   1.037   1.136   1.980  

	Coefficients:
					 Estimate Std. Error z value Pr(>|z|)    
	(Intercept)     7.679e-01  1.099e-01   6.985 2.85e-12 ***
	Duration       -3.556e-04  2.175e-05 -16.347  < 2e-16 ***
	KeySignature1  -2.967e-02  1.194e-02  -2.484 0.012997 *  
	KeySignature2   5.068e-02  1.103e-02   4.595 4.32e-06 ***
	KeySignature3  -4.779e-02  1.714e-02  -2.788 0.005297 ** 
	KeySignature4   7.960e-02  1.206e-02   6.600 4.11e-11 ***
	KeySignature5  -4.459e-02  1.246e-02  -3.577 0.000347 ***
	KeySignature6  -2.853e-03  1.336e-02  -0.213 0.830978    
	KeySignature7  -3.046e-02  1.067e-02  -2.854 0.004313 ** 
	KeySignature8  -3.006e-02  1.397e-02  -2.152 0.031382 *  
	KeySignature9   5.583e-02  1.106e-02   5.046 4.51e-07 ***
	KeySignature10 -8.518e-02  1.278e-02  -6.663 2.69e-11 ***
	KeySignature11 -1.225e-02  1.198e-02  -1.022 0.306698    
	Loudness        3.225e-02  5.406e-04  59.651  < 2e-16 ***
	Tempo           6.847e-04  7.777e-05   8.804  < 2e-16 ***
	TimeSignature1 -4.457e-01  1.098e-01  -4.060 4.90e-05 ***
	TimeSignature3 -4.004e-01  1.097e-01  -3.649 0.000264 ***
	TimeSignature4 -3.645e-01  1.096e-01  -3.327 0.000879 ***
	TimeSignature5 -3.929e-01  1.100e-01  -3.572 0.000354 ***
	TimeSignature7 -3.166e-01  1.108e-01  -2.857 0.004277 ** 
	---
	Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

	(Dispersion parameter for binomial family taken to be 1)

		Null deviance: 789824  on 570063  degrees of freedom
	Residual deviance: 784666  on 570044  degrees of freedom
	AIC: 784706

	Number of Fisher Scoring iterations: 4
	
Here we notice that our AIC is high, so we exclude some of our variables and run once again a new linear model: 


	> glm2<-glm(YearBucket ~ Duration + KeySignature + Tempo + Hotness, data=D, family=binomial)
	> summary(glm2)

	Call:
	glm(formula = YearBucket ~ Duration + KeySignature + Tempo + 
		Hotness, family = binomial, data = D)

	Deviance Residuals: 
		Min       1Q   Median       3Q      Max  
	-2.4303  -1.1216   0.6380   0.9074   1.8357  

	Coefficients:
					 Estimate Std. Error z value Pr(>|z|)    
	(Intercept)    -8.412e-01  2.003e-02 -41.990  < 2e-16 ***
	Duration       -2.345e-04  3.221e-05  -7.280 3.34e-13 ***
	KeySignature1  -7.022e-02  1.730e-02  -4.060 4.91e-05 ***
	KeySignature2   2.285e-02  1.587e-02   1.440  0.14988    
	KeySignature3  -9.863e-02  2.507e-02  -3.934 8.36e-05 ***
	KeySignature4   2.573e-02  1.729e-02   1.488  0.13668    
	KeySignature5  -8.292e-02  1.802e-02  -4.602 4.18e-06 ***
	KeySignature6  -4.151e-02  1.925e-02  -2.157  0.03102 *  
	KeySignature7  -1.831e-02  1.542e-02  -1.187  0.23525    
	KeySignature8  -8.545e-02  2.030e-02  -4.210 2.56e-05 ***
	KeySignature9   3.471e-02  1.594e-02   2.177  0.02948 *  
	KeySignature10 -8.644e-02  1.860e-02  -4.646 3.38e-06 ***
	KeySignature11 -2.410e-02  1.734e-02  -1.390  0.16461    
	Tempo           3.453e-04  1.099e-04   3.142  0.00168 ** 
	Hotness         3.710e+00  1.773e-02 209.232  < 2e-16 ***
	---
	Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

	(Dispersion parameter for binomial family taken to be 1)

		Null deviance: 446901  on 331006  degrees of freedom
	Residual deviance: 395094  on 330992  degrees of freedom
	  (239057 observations deleted due to missingness)
	AIC: 395124

	Number of Fisher Scoring iterations: 4
	
We reduced the AIC, but we can do better: 

	> glm4<-glm(YearBucket ~  Duration + ArtistLatitude + ArtistLongitude + KeySignature + Loudness + Tempo, data=D, family=binomial)
	> summary(glm4)
	
	AIC: 277524
	
Our final decision is this one: 

	> glm1<-glm(YearBucket ~ Duration + ArtistLatitude + ArtistLongitude + KeySignature + Loudness + Tempo + TimeSignature, data=D, family=binomial)
	> summary(glm1)

	Call:
	glm(formula = YearBucket ~ Duration + ArtistLatitude + ArtistLongitude + 
		KeySignature + Loudness + Tempo + TimeSignature, family = binomial, 
		data = D)

	Deviance Residuals: 
		Min       1Q   Median       3Q      Max  
	-1.6737  -1.1871   0.9238   1.1321   1.9913  

	Coefficients:
					  Estimate Std. Error z value Pr(>|z|)    
	(Intercept)      3.924e-01  1.981e-01   1.980  0.04768 *  
	Duration        -3.870e-04  3.708e-05 -10.438  < 2e-16 ***
	ArtistLatitude   9.074e-03  2.979e-04  30.458  < 2e-16 ***
	ArtistLongitude  2.843e-03  8.235e-05  34.521  < 2e-16 ***
	KeySignature1   -2.406e-02  2.034e-02  -1.183  0.23683    
	KeySignature2    4.185e-02  1.833e-02   2.282  0.02246 *  
	KeySignature3   -6.983e-02  2.783e-02  -2.509  0.01212 *  
	KeySignature4    9.747e-02  2.020e-02   4.824 1.41e-06 ***
	KeySignature5   -3.389e-02  2.038e-02  -1.663  0.09635 .  
	KeySignature6    3.799e-02  2.284e-02   1.663  0.09630 .  
	KeySignature7   -3.129e-02  1.779e-02  -1.759  0.07860 .  
	KeySignature8   -3.103e-02  2.328e-02  -1.333  0.18255    
	KeySignature9    7.265e-02  1.846e-02   3.935 8.32e-05 ***
	KeySignature10  -6.339e-02  2.151e-02  -2.947  0.00321 ** 
	KeySignature11   1.729e-02  2.055e-02   0.841  0.40036    
	Loudness         3.308e-02  8.796e-04  37.612  < 2e-16 ***
	Tempo            1.007e-03  1.314e-04   7.661 1.85e-14 ***
	TimeSignature1  -2.086e-01  1.974e-01  -1.057  0.29051    
	TimeSignature3  -1.747e-01  1.973e-01  -0.885  0.37599    
	TimeSignature4  -1.680e-01  1.971e-01  -0.852  0.39395    
	TimeSignature5  -1.978e-01  1.977e-01  -1.000  0.31718    
	TimeSignature7  -9.309e-02  1.990e-01  -0.468  0.63994    
	---
	Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

	(Dispersion parameter for binomial family taken to be 1)

		Null deviance: 281804  on 203555  degrees of freedom
	Residual deviance: 277470  on 203534  degrees of freedom
	  (366508 observations deleted due to missingness)
	AIC: 277514

	Number of Fisher Scoring iterations: 4
			