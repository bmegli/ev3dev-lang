#   Sample application for EV3 (client).
#
#   Note - script has not been tested yet after transfering to new RSclient syntax
#
#   It transfers the necessary files to EV3, sources the files
#   With the correctly built EV3 robot this application controls the robot so that:
#   -it looks around with infrared sensor (360 degree on medium motor with polling the infrared)
#   -the result is plotted on PC
#   -the user clicks on plot to guide the robot (roughly)
#
#   This script is intended to be run from PC (not EV3)  
#
#   Prerequsities: 
#   -R and Rserve installed on EV3
#   -RSclient package installed on PC
#   -remote connections enabled for Rserve on EV3
#   -working directory set to location of files (setwd on PC)
#
#   This is intented to work in tandem with ev3dev_sample.R 
#   ev3dev_sample.R is not required to be called manually on EV3 (this script does it)
#
#   The intented hardware for EV3 is:
#   -large motor on OUTPUT_B
#   -large motor on OUTPUT_C
#   -(optional) infrared sensor mounted on medium motor with long cable so that it can rotate 360 degrees and back
#
#     
#   Copyright (c) 2014 - Bartosz Meglicki
# 
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#  
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


# Setup the ip of EV3

ip="192.168.1.10"
#ip="10.1.6.163"
#ip="192.168.1.3"

# Set working directory to source file location:
# e.g. in RStudio Session->Set Working Directory -> To Source File Location

# End Setup

library(RSclient)
source("../ev3_dev_tools.R") #startRemoteRserve, upload, run

c=RS.connect(ip)
RS.eval(c, quote(print("It is ready.")))

UploadFile(c, "./ev3dev.R")
UploadFile(c, "ev3dev_sample.R")
RS.eval( c, source("ev3dev.R"))
RS.eval( c, source("ev3dev_sample.R") )

# END Setup

# Send some sample commands
RS.eval( c, Speak("Hello") )

RS.eval( c, Drive(left_motor, right_motor, 50) ) 



RS.eval( c, Look(head_motor, -360)) 
RS.eval( c, Look(head_motor, 0)) 
RS.eval( c, Look(head_motor, 360)) 
RS.eval( c, Sense(infrared))
RS.eval( c, Rotate(left_motor, right_motor, 90)) 

Degree=function(radian){ radian*180/pi }
Radian=function(degree){ degree*pi/180 }

PlotReadings=function(readings)
{
  plot(0,0, xlim=c(-100,100), ylim=c(-100,100), asp=1, col="red")
  
  x= 100*cos(seq(from=0, to=2*pi, by=0.05))
  y= 100*sin(seq(from=0, to=2*pi, by=0.05))
  lines(x,y, col="red")    
  
  readings=readings[readings[,2]<100,]
  x= readings[,2]*cos(Radian(90+readings[,1]))
  y= readings[,2]*sin(Radian(90+readings[,1]))
  
  points(x, y, col="blue")    
}

PlotReadingsUS=function(readings)
{
  plot(0,0, xlim=c(-300, 300), ylim=c(-300,300), asp=1, col="red")
  
  x= 255*cos(seq(from=0, to=2*pi, by=0.05))
  y= 255*sin(seq(from=0, to=2*pi, by=0.05))
  lines(x,y, col="red")    
  
  readings[,2]=readings[,2]/10
  readings=readings[readings[,2]<250,]
  x= readings[,2]*cos(Radian(90+readings[,1]))
  y= readings[,2]*sin(Radian(90+readings[,1]))
  
  points(x, y, col="blue")    
}


ControlRobot=function()
{
  point=locator(n=1)
  drive=sqrt(point$x^2+point$y^2)*0.7
  
  rotate=90-(Degree(atan2(point$y, point$x)))
  if(rotate>180)
    rotate=rotate-360
  
  list(rotate=round(rotate), drive=round(drive))  
}

X11()

while(1)
{
  readings=RS.eval( c, LookAround(head_motor, infrared))

  PlotReadings(readings)
  #PlotReadingsUS(readings)
  command=ControlRobot()
  
  rotation_command=paste("Rotate(left_motor, right_motor,", command$rotate, ")" ,sep="")  
  RS.eval( c, as.call(list(quote(Rotate), quote(left_motor), quote(right_motor), command$rotate)), lazy=FALSE)  
  drive_command=paste("Drive(left_motor, right_motor,", command$drive, ")" ,sep="")  
  RS.eval( c, as.call(list(quote(Drive), quote(left_motor), quote(right_motor), command$drive)), lazy=FALSE)
}

RS.close(c)
