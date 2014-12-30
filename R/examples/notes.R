#acceleration

acc=RS.eval(con, TestAcceleration(left, right, gyro, 40))
acc

plot(acc$accx, col=as.factor(acc$left_states))
plot(acc$accy, col=as.factor(acc$right_states))
plot(density(acc$accx[acc$left_states=="ramp_const"]))
plot(density(dc$right_dc[dc$right_states=="ramp_const"]))

thr_left_dc=max(dc$left_dc)+10L
thr_right_dc=max(dc$right_dc)+10L
thr_left_dc
thr_right_dc


for(i in 1:10)
{
  last=RS.eval(con, DriveThresholdTouchDC(left, right, infrared, ltouch, 100L, 60L, 40L, 2L, 53L, 55L))
  
  if(abs(last$infrared - last$mean_infrared)>20)
    next
  
  if( any(c("infrared_up", "touch", "left_dc", "right_dc") %in%  last$stop_reason))
    RS.eval(con,Drive(left, right, -10L))
  
  angle=as.integer(180-runif(1, 0, 90))
  if(sample(2, 1)==1) angle=-angle
  
  t=RS.eval(con, as.call(list(quote(Rotate), quote(left), quote(right), angle)), lazy=FALSE)  
}
