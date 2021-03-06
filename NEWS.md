### Updates 2.2.1
#### Performance Tuning / Restructuring
Switch to matrices instead of data.frames and a lot of restructuring and 
performance optimization of the whole algorithm.

The function **`genAlgo`**/**`windfarmGA`** and the plotting functions now accept SimpleFeature Polygons or coordinates in table format
with long, lat or x, y column names. The terrain effect model can now be activated only by setting `topograp` to TRUE and it will attempt to download the land cover raster from the European Environment Agency website.

- **`viewshed`** A new set of functions, to analyze the visual impact of a wind farm.    
The new functions for visual assessment are **`cansee`**, **`viewTo`**, **`rasterprofile`**, **`viewshed`**, **`plot_viewshed`**, **`interpol_view`**, **`getISO3`**, **`getDEM`**
- **`plot_farm_3d`** Experimental rayshader function

### Updates 1.2.1
#### Randomization
The output of **`genAlgo`** or **`windfarmGA`** can be further randomized/optimized with the following
functions:
- RandomSearch
- RandomSearchTurb

**`RandomSearch`** is used to randomize all turbines of the layout whereas
**`RandomSearchTurb`** is used to randomize a single turbine

**`RandomSearchPlot`** is used to plot the outputs of those functions, compared with the 
original result.

```sh
load(file = system.file("extdata/resultrect.rda", package = "windfarmGA"))
load(file = system.file("extdata/polygon.rda", package = "windfarmGA"))
Res = RandomSearchTurb(result = resultrect, Polygon1 = polygon, n=10)
RandomSearchPlot(resultRS = Res, result = resultrect, Polygon1 = polygon, best=2)
```

### Updates 1.2
#### Parallel Processing
```sh
## Runs the same optimization, but with parallel processing and 3 cores.
result_par <- genAlgo(Polygon1 = Polygon1, GridMethod ="h", n=12, Rotor=30,
                 fcrR=5,iteration=10, vdirspe = data.in,crossPart1 = "EQU",
                 selstate="FIX",mutr=0.8, Proportionality = 1,
                 SurfaceRoughness = 0.3, topograp = FALSE,
                 elitism=TRUE, nelit = 7, trimForce = TRUE,
                 referenceHeight = 50,RotorHeight = 100,
                 Parallel = TRUE, numCluster = 3)
PlotWindfarmGA(result = result_par, GridMethod = "h", Polygon1 = Polygon1)
```

### Updates 1.1
#### Optimization with Hexagonal Grid Cells
```sh
result_hex <- genAlgo(Polygon1 = Polygon1, GridMethod ="h", n=12, Rotor=30,
                  fcrR=5,iteration=10, vdirspe = data.in,crossPart1 = "EQU",
                  selstate="FIX",mutr=0.8, Proportionality = 1,
                  SurfaceRoughness = 0.3, topograp = FALSE,
                  elitism=TRUE, nelit = 7, trimForce = TRUE,
                  referenceHeight = 50,RotorHeight = 100)
PlotWindfarmGA(result = result_hex, GridMethod = "h", Polygon1 = Polygon1)
```
