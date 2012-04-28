## Functions for predictions and visualizations of Bixi data
library(KernSmooth)
rm(list=ls())
## Data

#d<-read.csv('montreal-2011-sample.csv',header=FALSE)


d<-read.csv('clean',header=FALSE,sep='|') # Vic's

lon_index<-2         #6
lat_index<-1         #5
response_index<-4    #12
times_index<-3       #1

## Colour setup
  colors<-c('black','blue','lightblue','lightblue','white')
  cus_col<-colorRampPalette(colors=colors, bias = 1, space = c("rgb", "Lab"),interpolate = c("linear", "spline"))

  tcol <- topo.colors(12)
  xrange=list(range(d[,lon_index]),range(d[,lat_index]))

## vector of timestamps
  times<-unique(d[,times_index])

## One map per unique timestamp
for(i in 1:length(times))
{
   at_time<-which(d[,times_index]==times[i])
   lon<-d[at_time,lon_index]
   lat<-d[at_time,lat_index]
   response<-d[at_time,response_index]

   dens<-bkde2D(cbind(lon,lat,response),gridsize=c(300,300),bandwidth=0.0015)
   png(paste(10+i,".png"))
   image(dens$x1,dens$x2,dens$fhat,col=cus_col(30),xlab='Lon',ylab='lat',main=i)
   dev.off()
   cat(i,'\n')
}

## Roll it
system('convert -delay 10 *.png head.gif')
system('rm *.png')


# Legending
#  colorlegend(posx=c(0.84,0.87),posy=c(0.15,0.85),col=cus_col(100),zlim=c(0,0.3),digit=2,main='Posterior\nprobability',zval=seq(0,0.3,0.05) )

