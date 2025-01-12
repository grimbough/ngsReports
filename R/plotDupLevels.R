#' @title Plot the combined Sequence_Duplication_Levels information
#'
#' @description Plot the Sequence_Duplication_Levels information for a set of
#' FASTQC reports
#'
#' @details
#' This extracts the Sequence_Duplication_Levels from the supplied object and
#' generates a ggplot2 object, with a set of minimal defaults. For multiple
#' reports, this defaults to a heatmap with block sizes proportional to the
#' percentage of reads belonging to that duplication category.
#'
#' If setting `usePlotly = FALSE`, the output of this function can be
#' further modified using standard ggplot2 syntax. If setting
#' `usePlotly = TRUE` an interactive plotly object will be produced.
#'
#' @param x Can be a `FastqcData`, `FastqcDataList` or file path
#' @param usePlotly `logical` Default `FALSE` will render using
#' ggplot. If `TRUE` plot will be rendered with plotly
#' @param labels An optional named vector of labels for the file names.
#' All filenames must be present in the names.
#' File extensions are dropped by default.
#' @param pwfCols Object of class [PwfCols()] to give colours for
#' pass, warning, and fail values in the plot
#' @param warn,fail The default values for warn and fail are 20 and 50
#' respectively (i.e. percentages)
#' @param lineCols Colours of the lines drawn for individual libraries
#' @param deduplication Plot Duplication levels 'pre' or 'post' deduplication.
#' Can only take values "pre" and "post"
#' @param plotType Choose between "heatmap" and "line"
#' @param cluster `logical` default `FALSE`. If set to `TRUE`,
#' fastqc data will be clustered using hierarchical clustering
#' @param dendrogram `logical` redundant if `cluster` is `FALSE`
#' if both `cluster` and `dendrogram` are specified as `TRUE`
#' then the dendrogram will be displayed.
#' @param heatCol Colour palette used for the heatmap
#' @param heat_w Relative width of the heatmap relative to other plot components
#' @param ... Used to pass additional attributes to theme() and between methods
#'
#'
#' @return A standard ggplot2 or plotly object
#'
#' @examples
#'
#' # Get the files included with the package
#' packageDir <- system.file("extdata", package = "ngsReports")
#' fl <- list.files(packageDir, pattern = "fastqc.zip", full.names = TRUE)
#'
#' # Load the FASTQC data as a FastqcDataList object
#' fdl <- FastqcDataList(fl)
#'
#' # Draw the default plot for a single file
#' plotDupLevels(fdl[[1]])
#'
#' plotDupLevels(fdl)
#'
#' @docType methods
#'
#' @import ggplot2
#' @importFrom stats hclust dist
#' @importFrom grDevices hcl.colors
#' @importFrom tidyselect contains
#' @importFrom forcats fct_inorder
#' @import tibble
#' @importFrom rlang "!!" sym
#'
#' @name plotDupLevels
#' @rdname plotDupLevels-methods
#' @export
setGeneric("plotDupLevels", function(
    x, usePlotly = FALSE, labels, pwfCols, ...){
  standardGeneric("plotDupLevels")
}
)
#' @rdname plotDupLevels-methods
#' @export
setMethod("plotDupLevels", signature = "ANY", function(
    x, usePlotly = FALSE, labels, pwfCols, ...){
  .errNotImp(x)
}
)
#' @rdname plotDupLevels-methods
#' @export
setMethod("plotDupLevels", signature = "character", function(
    x, usePlotly = FALSE, labels, pwfCols, ...){
  x <- FastqcDataList(x)
  if (length(x) == 1) x <- x[[1]]
  plotDupLevels(x, usePlotly, labels, pwfCols, ...)
}
)
#' @rdname plotDupLevels-methods
#' @export
setMethod("plotDupLevels", signature = "FastqcData", function(
    x, usePlotly = FALSE, labels, pwfCols, warn = 20, fail = 50,
    lineCols = c("red", "blue"), ...){

  mod <- "Sequence_Duplication_Levels"
  df <- getModule(x, mod)

  if (!length(df)) {
    dupPlot <- .emptyPlot("No Duplication Levels Module Detected")
    if (usePlotly) dupPlot <- ggplotly(dupPlot, tooltip = "")
    return(dupPlot)
  }

  ## Convert from wide to long
  df <- tidyr::pivot_longer(
    df, cols = contains("Percentage"),
    names_to = "Type", values_to = "Percentage"
  )
  df$Duplication_Level <- forcats::fct_inorder(df$Duplication_Level)
  df$Type <- stringr::str_replace(df$Type, "Percentage_of_", "% ")
  df$Type <- stringr::str_to_title(df$Type)
  df$Type <- paste(df$Type, "sequences")
  df$x <- as.integer(df$Duplication_Level)
  df$Percentage <- round(df$Percentage, 2)

  ## Drop the suffix, or check the alternate labels
  labels <- .makeLabels(x, labels, ...)
  labels <- labels[names(labels) %in% df$Filename]
  df$Filename <- labels[df$Filename]

  ## Get any theme arguments for dotArgs that have been set manually
  dotArgs <- list(...)
  allowed <- names(formals(theme))
  keepArgs <- which(names(dotArgs) %in% allowed)
  userTheme <- c()
  if (length(keepArgs) > 0) userTheme <- do.call(theme, dotArgs[keepArgs])

  ## Sort out the colours
  if (missing(pwfCols)) pwfCols <- ngsReports::pwf
  stopifnot(.isValidPwf(pwfCols))
  pwfCols <- setAlpha(pwfCols, 0.1)

  ## Set the background rectangles
  rects <- tibble(
    xmin = 0.5,
    xmax = max(df$x) + 0.5,
    ymin = c(0, warn, fail),
    ymax = c(warn, fail, 100),
    Status = c("PASS", "WARN", "FAIL")
  )

  ##Axis labels
  xlab <- gsub("_", " ", mod)
  ylab <- "Percentage (%)"

  dupPlot <- ggplot(data = df) +
    geom_rect(
      data = rects,
      aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = Status)
    ) +
    geom_line(aes(x, Percentage, colour = Type, group = Type)) +
    scale_fill_manual(values = getColours(pwfCols)) +
    scale_colour_manual(values = lineCols) +
    scale_x_continuous(
      breaks = unique(df$x),
      labels = levels(df$Duplication_Level),
      expand = c(0, 0)
    ) +
    scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) +
    facet_wrap(~Filename) +
    labs(x = xlab, y = ylab, colour = c()) +
    guides(fill = "none") +
    theme_bw() +
    theme(
      legend.position = c(1, 1),
      legend.justification = c(1, 1),
      legend.background = element_rect(colour = "black", linewidth = 0.2),
      plot.title = element_text(hjust = 0.5)
    )
  if (!is.null(userTheme)) dupPlot <- dupPlot + userTheme

  if (usePlotly) {
    tt <- c("colour", "Percentage")
    dupPlot <- dupPlot + theme(legend.position = "none")
    dupPlot <- suppressMessages(plotly::ggplotly(dupPlot, tooltip = tt))

    dupPlot <- suppressMessages(
      suppressWarnings(
        plotly::subplot(
          plotly::plotly_empty(),
          dupPlot,
          widths = c(0.14,0.86)
        )
      )
    )
    dupPlot <- plotly::layout(
      dupPlot,
      xaxis2 = list(title = xlab),
      yaxis2 = list(title = ylab)
    )

    ## Make sure there are no hovers over the background rectangles
    dupPlot$x$data <- lapply(dupPlot$x$data, .hidePWFRects)
  }

  dupPlot

}
)
#' @rdname plotDupLevels-methods
#' @export
setMethod("plotDupLevels",signature = "FastqcDataList", function(
    x, usePlotly = FALSE, labels, pwfCols, warn = 20, fail = 50,
    deduplication = c("pre", "post"), plotType = c("heatmap", "line"),
    cluster = FALSE, dendrogram = FALSE,  heatCol = hcl.colors(50, "inferno"),
    heat_w = 8, ...){

  mod <- "Sequence_Duplication_Levels"
  df <- getModule(x, mod)

  if (!length(df)) {
    dupPlot <- .emptyPlot("No Duplication Levels Module Detected")
    if (usePlotly) dupPlot <- ggplotly(dupPlot, tooltip = "")
    return(dupPlot)
  }

  ## Select the 'pre/post' option & clean up the data
  deduplication <- match.arg(deduplication)
  type <- dplyr::case_when(
    deduplication == "pre" ~ "Percentage_of_total",
    deduplication == "post" ~ "Percentage_of_deduplicated"
  )
  df <- df[c("Filename", "Duplication_Level", type)]
  df[[type]] <- round(df[[type]], 2)
  Duplication_Level <- c() # Here to avoid R CMD check issues

  ## Check the plotType
  plotType <- match.arg(plotType)

  ## These will begin in order, but may not stay this way
  ## in the following code
  df$Duplication_Level <- forcats::fct_inorder(df$Duplication_Level)
  dupLevels <- levels(df$Duplication_Level)

  ## Drop the suffix, or check the alternate labels
  labels <- .makeLabels(x, labels, ...)
  labels <- labels[names(labels) %in% df$Filename]
  key <- names(labels)

  ## Get any theme arguments for dotArgs that have been set manually
  dotArgs <- list(...)
  allowed <- names(formals(theme))
  keepArgs <- which(names(dotArgs) %in% allowed)
  userTheme <- c()
  if (length(keepArgs) > 0) userTheme <- do.call(theme, dotArgs[keepArgs])

  ## Sort out the colours
  if (missing(pwfCols)) pwfCols <- ngsReports::pwf
  stopifnot(.isValidPwf(pwfCols))


  if (plotType == "line") {

    ## Now set everything as factors
    df$Filename <- forcats::fct_inorder(labels[df$Filename])
    df$x <- as.integer(df$Duplication_Level)

    ## Make transparent for a line plot
    pwfCols <- setAlpha(pwfCols, 0.1)

    ## Set the background rectangles
    rects <- tibble(
      xmin = 0.5,
      xmax = max(df$x) + 0.5,
      ymin = c(0, warn, fail),
      ymax = c(warn, fail, 100),
      Status = c("PASS", "WARN", "FAIL")
    )

    dupPlot <- ggplot(df, aes(label = !!sym("Duplication_Level"))) +
      geom_rect(
        data = rects,
        aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = Status)
      ) +
      geom_line(aes(x, y = !!sym(type), colour = Filename)) +
      scale_fill_manual(values = getColours(pwfCols)) +
      scale_x_continuous(
        breaks = seq_along(dupLevels),labels = dupLevels, expand = c(0, 0)
      ) +
      scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) +
      labs(x = "Duplication Level", y = "Percentage of Total") +
      guides(fill = "none") +
      theme_bw()

    if (usePlotly) {

      tt <- c("colour", type, "Duplication_Level")
      dupPlot <- dupPlot + theme(legend.position = "none")
      dupPlot <- suppressMessages(plotly::ggplotly(dupPlot, tooltip = tt))

      ## Make sure there are no hovers over the background rectangles
      dupPlot$x$data <- lapply(dupPlot$x$data, .hidePWFRects)

    }


  }

  if (plotType == "heatmap") {

    dl <- "Duplication_Level"
    pt <- "Percentage_of_total"
    ## Set up the dendrogram
    clusterDend <- .makeDendro(df, "Filename", dl, type)
    dx <- ggdendro::dendro_data(clusterDend)
    if (dendrogram | cluster) {
      key <- labels(clusterDend)
    }
    if (!dendrogram) dx$segments <- dx$segments[0,]
    df$Filename <- factor(labels[df$Filename], levels = labels[key])

    ## Setup to plot in tiles for easier plotly compatability
    df <-  dplyr::arrange(df, Filename, Duplication_Level)
    df <- split(df, f = df[["Filename"]])
    df <- lapply(df, function(x){
      x$xmax <- cumsum(x[[pt]])
      x$xmax <- round(x[["xmax"]], 1) # Deal with rounding errors
      x$xmin <- c(0, x[["xmax"]][-nrow(x)])
      x
    })
    df <-  dplyr::bind_rows(df)
    df$ymax <- as.integer(df[["Filename"]]) + 0.5
    df$ymin <- df[["ymax"]] - 1

    ## Setup some more plotting parameters
    cols <- colorRampPalette(heatCol)(length(dupLevels))
    hj <-  0.5 * heat_w / (heat_w + 1 + dendrogram)
    dupPlot <- ggplot(
      df,
      aes(fill = !!sym(dl), total = !!sym(pt), label = Filename)
    ) +
      geom_rect(
        aes(
          xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, colour = !!sym(dl)
        )
      ) +
      ggtitle(gsub("_", " ", mod)) +
      scale_fill_manual(values = cols) +
      scale_colour_manual(values = cols) +
      scale_y_continuous(
        breaks = seq_along(levels(df$Filename)),
        labels = levels(df$Filename),
        expand = c(0, 0), position = "right"
      ) +
      scale_x_continuous(expand = c(0, 0)) +
      labs(x = pt, fill = "Duplication\nLevel") +
      guides(colour = "none") +
      theme_bw() +
      theme(
        plot.margin = unit(c(5.5, 5.5, 5.5, 0), "points"),
        plot.title = element_text(hjust = hj),
        axis.title.x = element_text(hjust = hj)
      )

    if (!is.null(userTheme)) dupPlot <- dupPlot + userTheme

    status <- getSummary(x)
    status <- subset(status, Category == "Sequence Duplication Levels")
    status$Filename <-
      factor(labels[status$Filename], levels = levels(df$Filename))

    dupPlot <-
      .prepHeatmap(dupPlot, status, dx$segments, usePlotly, heat_w, pwfCols)

  }

  dupPlot
}
)
