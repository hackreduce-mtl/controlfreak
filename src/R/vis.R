## Functions for predictions and visualizations of Bixi data
library(KernSmooth)
rm(list=ls())
## Data

#d<-read.csv('montreal-2011-sample.csv',header=FALSE)
   name <- function(day)
   {
      if (day <= 31)
      return(paste("Jan ", day))
      if (day <= 60)
      return(paste("Feb ", (day - 31)))
      if (day <= 91)
      return(paste("Mar ", (day - 60)))
      if (day <= 121)
      return(paste("Apr ",(day - 91)))
   }





d<-read.csv('results2.out',header=FALSE,sep=' ') # Vic's

lon_index<-3         #6
lat_index<-2         #5
response_index<-4    #12
times_index<-1       #1

## Colour setup
  colors<-c('black','blue','lightblue','lightblue','white')
  cus_col<-colorRampPalette(colors=colors, bias = 1, space = c("rgb", "Lab"),interpolate = c("linear", "spline"))
   
  tcol <- topo.colors(12)
  xrange=list(range(d[,lon_index]),range(d[,lat_index]))

## vector of timestamps
  times<-unique(d[,times_index])
  #times<-sort(times)
 
## One map per unique timestamp
for(i in 1:length(times))
{
   
   at_time<-which(d[,times_index]==times[i])
   hour<-(times[i] %% 100) +1
   lon<-d[at_time,lon_index]
   lat<-d[at_time,lat_index]
   response<-d[at_time,response_index]

   dens<-bkde2D(cbind(lon,lat,response),range.x=xrange,gridsize=c(300,300),bandwidth=0.0015)
   png(paste(10000+i,".png",sep=''))
   image(dens$x1,dens$x2,dens$fhat,col=cus_col(30),xlab='Lon',ylab='lat',main=paste(name(floor(times[i]/100)),'hour:',hour))
   dev.off()
   cat(times[i],'\n')
}

## Roll it
#system('convert -delay 10 *.png head.gif')



# Legending
#  colorlegend(posx=c(0.84,0.87),posy=c(0.15,0.85),col=cus_col(100),zlim=c(0,0.3),digit=2,main='Posterior\nprobability',zval=seq(0,0.3,0.05) )

