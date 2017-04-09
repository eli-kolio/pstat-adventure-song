# Million Songs Dataset statistical analysis
This is the manifestation of a project in "Applied Statistics" for 3rd year students at the [Faculty of Mathematics and Informatics](http://fmi.uni-sofia.bg/) of Sofia University.
Our main goal here will be to process some subset of the million songs dataset and extract meaningful correlations between the parameters.

## LaTeX and project presentation/documentation
You can find documentation for the project as LaTeX scripts and PDFs in the "Project Documentation" subfolder.

## Preparing the dataset

The [million songs dataset](https://labrosa.ee.columbia.edu/millionsong/) is in the exotic HDF5 format. It contains a lot of "local" file information (song segments, tempos and audio characteristics for each segment, etc). They could thus be used for audio recognition and song segment recognition. Here, however, we will focus on more global characteristics of the songs. We will be investigating *Album*, *Artist* and *Song* details like release year, tempo, popularity (refered to as "hotness" in the dataset), loudness, etc. to produce a CSV that is edible by R, we needed to create a script, which can be found [here](https://github.com/nikox94/Million-Song-Dataset-HDF5-to-CSV). This extracts the attributes we need from the HDF5 file and converts them to CSV. We have a sample dataset of a 1% subset of the million songs, i.e. we have 10,000 songs in the sample dataset. It is about 2MB and can easily be worked with to produce prototypes, which can then be run on the complete dataset if tractable. To get the whole 1,000,000 songs as a CSV, an Amazon machine was launched, with the dataset (280GB) attached as an Amazon EBS Volume (Amazon supports Million Songs as a public dataset and has an available copy for mounting). This was all run in the cloud, with our script currently running through the whole dataset, extracting the data we need. The resulting CSV should be 200MB and the total running time of the extraction should be 30 hours. The used EBS volume is an SSD, but we seem to be reaching some other bottleneck (CPU usage, RAM, SSD iops all look fine). My suspicion is that the bottleneck is that the Amazon Volume is actually created on the fly as data from the Amazon Snapshot is being read.

## Installation
You need to have some form of R installed in order to work with the dataset. We will provide sample scripts for manipulating the data and plotting.

## Setting up for data exploration
To load the sample data subset do the following in an R console, with the "R" folder of this project being the working directory of R.

	Some code in R
	Including read.csv(.... headers=true, ....)
	.......

And the we could do some regressions on this. But first, let's do some sample statistics on the data.

	//To be continued
