# Web/radar Diagram Script

# plot_indicators function from: https://github.com/r4atlantis/common_scenarios_analysis/blob/master/R/plot_indicators.R
# Minor changes made to suit our purposes
plot_indicators <- function(ind,
                            colvec=c("#66c2a5","#fc8d62","#8da0cb"),
                            legend_labels=paste("Scenario ",1:3,sep=""),
                            axis_labels=1:8,
                            plotfile='indicator_plot.pdf',
                            MainTitle=NULL,
                            standardized=FALSE, 
                            autodetectAxisLimits=FALSE, ...) {
  # Args:
       # MainTitle: Adds a main title to the plot
       # all other arguments from: https://github.com/r4atlantis/common_scenarios_analysis/blob/master/R/plot_indicators.R
  
  #throw warning if Isaac forgets to use a color vector the length of his scenarios
  if (length(colvec)<nrow(ind)) {
    print("YOU SUPPLIED A COLOR VECTOR THAT IS SHORTER THAN THE NUMBER OF SCNEARIOS")
    print("COLORS WILL BE RECYCLED AND YOU WON'T BE ABLE TO TELL SCENARIOS APART")
    stop("Stopped function plot_indicators for your own sanity")
  }
  
  # Rescale data for performance metrics (so larger values are better) and pick out optimal value
  Scaled_ind <- NULL
  MaxAxis <- NULL
  
  # Below are metrics and corresponding translated label used for scaling (spaces and < > must be replaced with . below)
     # "PropSSBrelSSBmsy"                 : "Prop Year Biomass < Bmsy"
     # "PropSSBrelhalfSSBmsy"             : "Probability of Overfished B < 0.5 Bmsy"
     # "MedSSBrelSSBzero"                 : "SSB Relative to Unfished Biomass" 
     # "PropSSBrel30_75SSBzero"           : "Prop Year SSB is 30-75% of SSB Zero"
     # "SurpProd"                         : "Surplus Production"
     # "MedPredAvWt_status"               : "Tuna Weight Status" 
     # "AvPropYrs_okBstatusgf"            : "Prop Year Good Dogfish Biomass" 
     # "PropFrelFmsy"                     : "Prop Year Overfishing Occurs F > Fmsy"
     # "YieldrelMSY"                      : "Yield Relative to MSY"
     # "Yield"                            : "Yield"
     # "PropClosure"                      : "Prop Year Closure Occurs"
     # "p50_NR"                           : "Net Revenue for Herring"
     # "NetRevEquilibrium"                : "Prop Year Net Revenue at Equilibrium"
     # "Yvar"                             : "Interannual Variation in Yield"
     # "MedPropYrs_goodProd_Targplustern" : "Prop Year Tern Production > 1"

  for(NCol in 1:ncol(ind)){
    if(colnames(ind)[NCol] == "Yield.Relative.to.MSY" | colnames(ind)[NCol] == "Tuna.Weight.Status" |
       colnames(ind)[NCol] == "Prop.Year.Good.Dogfish.Biomass" | colnames(ind)[NCol] == "Yield" |
       colnames(ind)[NCol] == "Prop.Year.Tern.Production...1" | colnames(ind)[NCol] == "SSB.Relative.to.Unfished.Biomass" |
       colnames(ind)[NCol] == "Surplus.Production" | colnames(ind)[NCol] == "Prop.Year.SSB.is.30-75%.of.SSB.Zero" | 
       colnames(ind)[NCol] == "Prop.Year.Net.Revenue.at.Equilibrium"){
      # No data scaling necessary, larger value is preferred
      Scaled_ind <- cbind(Scaled_ind, ind[ ,NCol])
      
      MaxAxis <- c(MaxAxis, ceiling(max(Scaled_ind[ ,NCol])))
      
    } else if(colnames(ind)[NCol] == "Probability.of.Overfished.B...0.5.Bmsy" | colnames(ind)[NCol] == "Prop.Year.Closure.Occurs" | 
              colnames(ind)[NCol] ==  "Prop.Year.Biomass...Bmsy" | colnames(ind)[NCol] == "Prop.Year.Overfishing.Occurs.F...Fmsy"){
      # Scale probability data to: 1-Data
      Scaled_ind <- cbind(Scaled_ind, 1-ind[ ,NCol]) # I don't think these transformations are working
      
      # print(1-ind[,NCol])
      # print(ind[,NCol])
      MaxAxis <- c(MaxAxis, ceiling(max(Scaled_ind[ ,NCol])))

    } else if(colnames(ind)[NCol] == "Interannual.Variation.in.Yield"){
      # Scale data to: 1/Data
      Scaled_ind <- cbind(Scaled_ind, 1/ind[ ,NCol])
      MaxAxis <- c(MaxAxis, ceiling(max(Scaled_ind[ ,NCol])))
      
    } else if(colnames(ind)[NCol] == "Net.Revenue.for.Herring"){
      # Scale data to: Data/10
      Scaled_ind <- cbind(Scaled_ind, ind[ ,NCol]/10)
      MaxAxis <- c(MaxAxis, ceiling(max(Scaled_ind[ ,NCol])))

    } else {
      print(colnames(ind)[NCol])
      # Any performance metric not specified above is not scaled
      Scaled_ind <- cbind(Scaled_ind, ind[,NCol])
      MaxAxis <- c(MaxAxis, ceiling(max(Scaled_ind[ ,NCol])))
    }
  }
  
  colnames(Scaled_ind) <- colnames(ind) #MSE_PerformanceMetricVector
  #print(Scaled_ind)
  #print(ind)
  ##################
  # print(ind[,1])   # Check data format
  # print(1/ind[,2])
  # print(1-ind[,3])
  # print(1-ind[,4])
  # print(Scaled_ind)
  
  
  
  # Set aa2 equal to data
  aa2 <- Scaled_ind
  #make all in zero to max(Scaled_ind), can add code here to retain 0->1 for proportion indicators.
  aa1 <- MaxAxis            # /?????? get rid of these 2 lines, pass vector 
  # Set max value for axes
  aa0 <- aa1 
  # Set min value (often 0) for axes
  aa0[] <-0 
  
  
  # IK hack:
  # numOf0pt5Segments <- ceiling(max(Scaled_ind,na.rm=TRUE)/0.5)
  # numOf0pt5Segments <- ceiling(MaxAxis/0.5) # instead scale to provided MaxAxis value (standardizes axis across diagrams rather than just picking best for 1 diagram)
  
  if (standardized) {
    aa1[] <- 2.0
    aa0[] <- 0
    aa3 <- rep(1,length(aa1))
  }
  
  if (autodetectAxisLimits)  #IK HACK to make it automatically fit plot to axis limits of radar
  {
    aa1[] <- 0.5*numOf0pt5Segments   
  }
  
  #combine to 
  new_dat <- as.data.frame(rbind(aa1,aa0,aa2)) # max, min, data
  lwd_use <- rep(4,nrow(Scaled_ind))
  col_use <- colvec
  if (standardized) {
    new_dat <- as.data.frame(rbind(aa1,aa0,aa3,aa2))
    col_use <- c(gray(0.1),col_use)
    lwd_use <- c(0.5,lwd_use)
  }
  
  #axis_labels <- names(new_dat)
  axis_labels <- rep(axis_labels,length=ncol(new_dat))
  #legend_labels <- Scaled_ind[,1]
  legend_labels <- rep(legend_labels,length=nrow(Scaled_ind))
 
  if (autodetectAxisLimits)
  {
    plotfile <- sub("IndicatorPlot","IndicatorPlotAutoAxis", plotfile)
  }
  
  # For high resolution use line 141 not 140, 3 may be adjusted to change resolution
  png(file=plotfile, res=72*3, width=480*3, height=480*3)
  #png(file=plotfile)

  par(mar=c(0,3,3,0), oma=c(0,0,0,0), xpd=TRUE)

  # Original:
  # if (autodetectAxisLimits) # Set axes labels automatically when autodetectAxisLimits = TRUE ### for some reason the true option is not working
  # {
  #   fmsb::radarchart(new_dat,pty=32,plwd=lwd_use,cglcol=gray(0.1),xlim=c(-1.5,2),
  #                    ylim=c(-1.5,1.5),pcol=col_use,plty=1,vlabels=axis_labels,axistype=4,seg= numOf0pt5Segments , caxislabels = as.character(seq(0, 0.5*numOf0pt5Segments ,0.5)))  #seg=5) #
  # } else  
  # {     # IF want All axes set to 2 as limit
  #   
  #   fmsb::radarchart(new_dat,pty=32,plwd=lwd_use,cglcol=gray(0.1),xlim=c(-1.5,2),
  #                    ylim=c(-1.5,1.5),pcol=col_use,plty=1,vlabels=axis_labels,axistype=4,seg=4, caxislabels=c("0","0.5","1","1.5","2"))
  # }
  
  if (autodetectAxisLimits) # Set axes labels automatically when autodetectAxisLimits = TRUE ### for some reason the true option is not working, try setting upper limit to MaxAxis
  { # Shouldn't use TRUE option
    fmsb::radarchart(new_dat,pty=32,plwd=lwd_use,cglcol=gray(0.1),xlim=c(-1.5,2),
                     ylim=c(-1.5,1.5),pcol=col_use,plty=1,vlabels=axis_labels,axistype=4,seg= numOf0pt5Segments , caxislabels = as.character(seq(0, 0.5*numOf0pt5Segments ,0.5)))  #seg=5) #
  } else
  {     # IF want All axes set with best performance on outside edge

    fmsb::radarchart(new_dat,pty=32,plwd=lwd_use,cglcol=gray(0.1),xlim=c(-1.5,2),
                     ylim=c(-1.5,1.5),pcol=col_use,plty=1,vlabels=axis_labels,axistype=0,seg=4)
  }
  
  # Add main title to graph
  text(0,1.7,labels=MainTitle, cex=1.5)
  
  write.csv(new_dat, file = paste(plotfile, ".csv"))              
  
  # Add legend
  legend(0.7,1.8,legend=legend_labels,lwd=3,col=colvec,cex=1,bty='n')
  
  dev.off()
}


WebDiagramPlots <- function(Data=NULL, PlotColor = NULL, LegendLabels = NULL, AxisLabels=NULL, OutputFileName=NULL, MainTitle=NULL, MaxAxis=NULL){
  # Read in data and produce web diagram plot
  # plot_indicators function from: https://github.com/r4atlantis/common_scenarios_analysis/blob/master/R/plot_indicators.R
  # Minor alterations were made to produce clean graphic
  
  # Args:
       # Data: Name of data file
            # Should be a table with a first colum containing scenario information (Control rule or operating model names), and one column for each performance metric
       # PlotColor: Vector of colors, must be same length as nrow(Data)
       # LegendLabels: Vector of labels for legend (should match first column of Data)
       # AxisLabels: Vector of labels for outside of web diagram (should match columnames, excluding first column containing senario names)
       # OutputFileName: String containing name of output file
       # MainTitle: String containing title for web/radar plot
       # MaxAxis: Sets maximum value for the axis
            # Should be max value across all web diagram data sets so these diagrams can be directly compared
  # Returns:
       # PNG file with web diagram for a single OM or CR depending on 
  
  library(fmsb)
  
  Data <- read.table(Data)
  Data <- as.data.frame(Data)
  
  plot_indicators(ind=Data,
                  colvec=PlotColor,
                  legend_labels = LegendLabels,
                  axis_labels = AxisLabels,
                  plotfile = OutputFileName,
                  standardized = FALSE, 
                  autodetectAxisLimits = FALSE,
                  # autodetectAxisLimits = FALSE, # This was changed because the option for TRUE was not working properly ??????
                  MainTitle = MainTitle,
                  MaxAxis = MaxAxis)
}


