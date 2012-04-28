#!/usr/bin/Rscript --no-save
library(KernSmooth)

## Data in
data_file<-commandArgs(TRUE)[1]
d<-read.csv(data_file,header=FALSE)

time<-gsub(".csv","",data_file)
plot_path<-paste(time,'.png',sep='')


cat(data_file, "\n")
cat(plot_path, "\n")

lon_index<-3         #6
lat_index<-2         #5
response_index<-4    #12

## Colour setup
  colors<-c('black','blue','lightblue','lightblue','white')
  cus_col<-colorRampPalette(colors=colors, bias = 1, space = c("rgb", "Lab"),interpolate = c("linear", "spline"))

  tcol <- topo.colors(12)
  xrange=list(range(d[,lon_index]),range(d[,lat_index]))


## One map per unique timestamp
   lon<-d[,lon_index]
   lat<-d[,lat_index]
   response<-d[,response_index]

   ##Kernal estimation
   dens<-bkde2D(cbind(lon,lat,response),gridsize=c(300,300),bandwidth=0.0015)

   png(plot_path)
      image(dens$x1,dens$x2,dens$fhat,col=cus_col(30),xlab='Lon',ylab='lat')
   dev.off()


###
