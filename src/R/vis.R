## Visualizations of Bixi data
library(KernSmooth)
library(lubridate)
library(maptools)

rm(list=ls())


## Data ##
d<-read.csv('results2.out',header=FALSE,sep=' ') # Vic's
mtl<-readShapePoly('./mtlshp/montreal_borough_borders.shp')

lon_index<-3         #
lat_index<-2         #
response_index<-4    #
times_index<-1       #

## GIS business ##
  nit <- nrow(mtl) 
  boundaries<-list()
  allb<-NULL
  for(i in 1:nit)
  {
    boundaries[[i]]<-slot(slot((slot(mtl, 'polygons'))[[i]], 'Polygons')[[1]], 'coords')
    allb<-rbind(allb,boundaries[[i]])
  }
  #plot(allb)
  add_lines<-function()
  {
    for(i in 1:nit)
      lines(boundaries[[i]],col='white')
  }  
      

## Colour setup ##
  colors<-c('black','blue','lightblue','lightblue','white')
  cus_col<-colorRampPalette(colors=colors, bias = 1, space = c("rgb", "Lab"),interpolate = c("linear", "spline"))
   
  tcol <- topo.colors(12)
  xrange=list(range(d[,lon_index]),range(d[,lat_index]))

## Vector of timestamps ##
  hours<-d[,times_index] %% 100
  days<-floor( d[,times_index] / 100)
  day_0 <- ymd("2011-12-31",tz='GMT') 
  
  postimes<- day_0 + ddays(days) + dhours(hours+1)
  postimes<-with_tz(postimes,tz='EST')
  d[,times_index]<-postimes   

  valid_times <- interval(ymd(20120403,tz='EST'), ymd(20120501,tz='EST'))
  d<-subset(d,postimes %within% valid_times)
  times<-unique(d[,times_index])

 flux<-numeric(length(times))
 maxdens<-1

## One map per unique timestamp
collect<-function(gen_plot=FALSE)
{
   for(i in 1:length(times)) #150:700) #150:700)
   {
      at_time<-which(d[,times_index]==times[i]) 
      lon<-d[at_time,lon_index]
      lat<-d[at_time,lat_index]
      response<-d[at_time,response_index]

      flux[i]<-sum(response)

      dens<-bkde2D(cbind(lon,lat,response),range.x=xrange,gridsize=c(300,300),bandwidth=0.0015)
      maxdens<-max(c(maxdens,dens$fhat*flux[i]))

      if(gen_plot)
      {
         png(paste("imgs/",format(times[i],"%y-%m-%d-%H"),".png",sep='') )
           image(dens$x1,dens$x2,dens$fhat*flux[i],col=cus_col(30),xlab='Lon',ylab='lat',main= format(times[i],"%y-%m-%d: %H h") ,zlim=c(0,360900))
           add_lines()
         dev.off()
      }
      print(format(times[i],"%y-%m-%d: %H h"))
   }
   return(flux)
}


flux<-collect()

ind_order<-order(times)

png('whole_span.png',width=960)
   par(cex=1.5,lwd=2)
   plot(times[ind_order],flux[ind_order],xlab='Time',ylab='Flux (bikes/hour)',type='l')
dev.off()

## Pull out a single week 
april18 <- interval(ymd(20120407,tz='EST'), ymd(20120415,tz='EST'))
span_index<-times[ind_order] %within% april18

png('one_week.png',width=960)
   par(cex=1.5,lwd=2)
   plot(times[ind_order[span_index]],flux[ind_order[span_index]],xlab='Time',ylab='Flux (bikes/hour)',type='l')
dev.off()



