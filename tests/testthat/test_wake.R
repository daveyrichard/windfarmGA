context("Wake Calculation")

library(testthat)
library(windfarmGA)
library(sp)
library(raster)

test_that("Test Wake Functions", {
  ## Input Data ---------------------
  ###########################################
  polYgon <- Polygon(rbind(c(0, 0), c(0, 2000),
                           c(2000, 2000), c(2000, 0)))
  polYgon <- Polygons(list(polYgon),1);
  polYgon <- SpatialPolygons(list(polYgon))
  Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
  +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  proj4string(polYgon) <- CRS(Projection);
  wnkl=20; dist=100000; dirct=0
  t <- as.matrix(cbind(x=runif(10,0,raster::extent(polYgon)[2]),
       y=runif(10,0,raster::extent(polYgon)[4])))

  ## Test WinkelCalc Function --------------
  ###########################################
  Aa= as.numeric(cbind(1,1))
  Bb= as.numeric(cbind(10,3))
  Cc= as.numeric(cbind(10,1))
  Angles <- WinkelCalc(Aa,Bb,Cc);
  expect_false(any(is.na(Angles)))
  expect_true(round(colSums(Angles)) == 180)
  rm(Angles)
  
  Aa= cbind(0,0)
  Bb= cbind(-5,3)
  Cc= cbind(10,1)
  Angles <- WinkelCalc(Aa,Bb,Cc);
  expect_false(any(is.na(Angles)))
  expect_true(round(colSums(Angles)) == 180)
  rm(Angles)
  
  Aa= c(0,0)
  Bb= c(-5,3)
  Cc= c(10,1)
  Angles <- WinkelCalc(Aa,Bb,Cc);
  expect_false(any(is.na(Angles)))
  expect_true(round(colSums(Angles)) == 180)
  rm(Angles)
  
  Aa= data.frame(cbind(0,0))
  Bb= data.frame(cbind(-50,30.4))
  Cc= data.frame(cbind(10,44))
  Angles <- WinkelCalc(Aa,Bb,Cc);
  expect_false(any(is.na(Angles)))
  expect_true(round(colSums(Angles)) == 180)
  rm(Angles)
  
  # plot(rbind(Aa,Bb,Cc,Aa), type="b", xlab="x",ylab="y");
  # points(x=Aa[1],y=Aa[2],col="green",pch=20);
  # points(x=Bb[1],y=Bb[2],col="red",pch=20);
  # points(x=Cc[1],y=Cc[2],col="blue",pch=20)
  # Angles <- WinkelCalc(Aa,Bb,Cc);
  # text(rbind(Aa,Bb,Cc),labels=paste(LETTERS[1:3], round(Angles,2)),pos=1)
  
  
  ## Test VekWinkelCalc Function --------------
  ###########################################
  distanz <- 100000
  ## Evaluate and plot for every turbine all other potentially influencing turbines
  potInfTur <- list()
  for (i in 1:(length(t[,1]))) {
    potInfTur[[i]] <- VekWinkelCalc(t = t, o = i, wkl = wnkl,
                     distanz = distanz, polYgon = polYgon, plotAngles=FALSE);
  }
  expect_false(all(unlist(sapply(potInfTur, is.na))))
  dr <- do.call("rbind", potInfTur)
  expect_true(all((dr[dr$Ax == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((dr[dr$Ay == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((dr[dr$Cx == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((dr[dr$Cy == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((dr[dr$Ax != 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) != 0))
  
  ## Same With Lapply
  potInfTurLP <- lapply(1:length(t[,1]), function(i) {
    VekWinkelCalc(t = t, o = i, wkl = wnkl,
                  distanz = distanz, polYgon = polYgon, plotAngles=FALSE);
  })
  expect_true(identical(potInfTurLP,potInfTur))
  expect_true(all.equal(potInfTurLP,potInfTur))
  expect_false(all(unlist(sapply(potInfTurLP, is.na))))
  
  
  ## Test InfluPoints Function --------------
  ###########################################
  resInfluPoi <- InfluPoints(t,wnkl,dist,polYgon,dirct)
  expect_is(resInfluPoi, "list")
  expect_true(all(sapply(resInfluPoi, class) == "data.frame"))
  expect_output(str(resInfluPoi), "List of 10")
  expect_false(any(unlist(sapply(resInfluPoi, is.na))))
  df <- do.call("rbind", resInfluPoi)
  expect_true(all((df[df$Ax == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((df[df$Ax != 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) != 0))
  
  ## Bigger Angle
  wnkl=50
  t <- as.matrix(cbind(x=runif(10,0,raster::extent(polYgon)[2]),
                       y=runif(10,0,raster::extent(polYgon)[4])))
  resInfluPoiWin <- InfluPoints(t,wnkl,dist,polYgon,dirct)
  expect_true(all(sapply(resInfluPoiWin, class) == "data.frame"))
  expect_output(str(resInfluPoiWin), "List of 10")
  expect_false(any(unlist(sapply(resInfluPoiWin, is.na))))
  df1 <- do.call("rbind", resInfluPoiWin)
  expect_true(all((df1[df1$Ax == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((df1[df1$Ax != 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) != 0))
  expect_true(nrow(df1) > nrow(df))
  rm(df1, resInfluPoi)
  
  ## More Points and bigger Angle
  t <- as.matrix(cbind(x=runif(20,0,raster::extent(polYgon)[2]),
                       y=runif(20,0,raster::extent(polYgon)[4])))
  resInfluPoi <- InfluPoints(t,wnkl,dist,polYgon,dirct)
  expect_true(all(sapply(resInfluPoi, class) == "data.frame"))
  expect_output(str(resInfluPoi), "List of 20")
  expect_false(any(unlist(sapply(resInfluPoi, is.na))))
  df1 <- do.call("rbind", resInfluPoi)
  expect_true(all((df1[df1$Ax == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((df1[df1$Ax != 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) != 0))
  rm(resInfluPoi)
  
  ## Same Points & Smaller Angle
  wnkl <- 10
  resInfluPoi <- InfluPoints(t,wnkl,dist,polYgon,dirct)
  expect_true(all(sapply(resInfluPoi, class) == "data.frame"))
  expect_output(str(resInfluPoi), "List of 20")
  expect_false(any(unlist(sapply(resInfluPoi, is.na))))
  df2 <- do.call("rbind", resInfluPoi)
  expect_true(all((df2[df2$Ax == 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) == 0))
  expect_true(all((df2[df2$Ax != 0,c("Ay","Cx","Cy","Laenge_C","Laenge_B","Laenge_A","alpha","betha","gamma")]) != 0))
  expect_true(nrow(df1) > nrow(df2))
  
  
  ## Test calculateEn Function ----------------------------
  ###########################################
  ## Initialize a dummy wind speed raster with value 1
  windraster <- raster::rasterize(polYgon, raster::raster(
    raster::extent(polYgon),
    ncol=180, nrow=180),field=1)
  
  ## Create a uniform and unidirectional wind data.frame and plot the
  ## resulting wind rose
  data.in <- as.data.frame(cbind(ws=12,wd=0))

  ## Assign the rotor radius and a factor of the radius for grid spacing.
  Rotor= 50; fcrR= 3
  resGrid <- GridFilter(shape = polYgon, resol = Rotor*fcrR, prop=1,
                        plotGrid = F)

  ## Create an initial population with the indexed Grid, 15 turbines and
  ## 100 individuals.
  resStartGA <- StartGA(Grid = resGrid[[1]],n = 15,nStart = 100)
  expect_true(all(sapply(resStartGA, length) == 4))
  expect_true(all(sapply(resStartGA, nrow) == 15 ))
  expect_true(length(resStartGA) == 100)
  expect_false(any(sapply(resStartGA, is.na)))
  
  ## Calculate the expected energy output of the first individual of the
  ## population.
  resCalcEn <- calculateEn(sel=resStartGA[[1]],referenceHeight= 50,
                          RotorHeight= 50, SurfaceRoughness = 0.14,wnkl = 20,
                          distanz = 100000, resol = 200,dirSpeed = data.in,
                          RotorR = 50, polygon1 = polYgon, topograp = FALSE,
                          windraster = windraster)
  
  expect_output(str(resCalcEn), "List of 1")
  df <- do.call(rbind, resCalcEn)
  expect_true(all(df[df$A_ov != 0,"TotAbschProz"] != 0))
  expect_true(all(df[df$TotAbschProz != 0,"V_New"] < df[df$TotAbschProz != 0,"Windmean"]))
  
  expect_false(any(unlist(sapply(resCalcEn, is.na))))
  expect_true(all(df$Rect_ID %in% resGrid[[1]]$ID))
  rm(resCalcEn, df)
  
  ## 2 Wind Directions 
  data.in <- as.data.frame(cbind(ws=c(12,12),wd=c(0,30)))
  resCalcEn <- calculateEn(sel=resStartGA[[1]],referenceHeight= 50,
                          RotorHeight= 50, SurfaceRoughness = 0.14,wnkl = 20,
                          distanz = 100000, resol = 200,dirSpeed = data.in,
                          RotorR = 50, polygon1 = polYgon, topograp = FALSE,
                          windraster = windraster)
  
  expect_output(str(resCalcEn), "List of 2")
  df <- do.call(rbind, resCalcEn)
  expect_true(all(df[df$A_ov != 0,"TotAbschProz"] != 0))
  expect_true(all(df[df$TotAbschProz != 0,"V_New"] < df[df$TotAbschProz != 0,"Windmean"]))
  
  expect_false(any(unlist(sapply(resCalcEn, is.na))))
  expect_true(all(df$Rect_ID %in% resGrid[[1]]$ID))
  
  
  
  

})







