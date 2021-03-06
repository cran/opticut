plot.multicut <-
function(x, which = NULL, cut, sort,
las, ylab="Relative abundance", xlab="Strata",
show_I=TRUE, show_S=TRUE, hr=TRUE, tick=TRUE,
theme, mar=c(5, 4, 4, 4) + 0.1, bty="o",
lower=0, upper=1, pos=0, horizontal=TRUE, ...)
{
    if (missing(las))
        las <- if (horizontal) 1 else 2
    if (pos < -1 || pos > 1)
        stop("BTW, pos must be in [-1, 1]")
    if (lower < 0 || lower > 1)
        stop("BTW, lower must be in [0, 1]")
    if (upper < lower || lower > 1)
        stop("BTW, upper must be in [lower, 1]")
    if (missing(cut))
        cut <- getOption("ocoptions")$cut
    if (missing(sort))
        sort <- getOption("ocoptions")$sort
    if (is.logical(sort)) {
        sort_r <- sort[1L]
        sort_c <- sort[1L]
    } else {
        sort_r <- 1 %in% sort
        sort_c <- 2 %in% sort
    }
    if (!is.null(which)) {
        x$species <- x$species[which]
    }
    ss <- summary(x)
    xx <- ss$summary
    bp <- ss$mu
    bp <- t(apply(bp, 1, function(z) (z-min(z)) / max(z-min(z))))
    bp01 <- ss$bestpart
    if (!any(xx$logLR >= cut)) {
        warning("All logLR < cut: cut ignored")
        rkeep <- rep(TRUE, nrow(xx))
    } else {
        rkeep <- xx$logLR >= cut
        #bp <- bp[rkeep, , drop=FALSE]
        #xx <- xx[rkeep, , drop=FALSE]
    }
    if (sort_r) {
        bp <- bp[attr(ss$bestpart, "row.order")[rkeep],,drop=FALSE]
        bp01 <- bp01[attr(ss$bestpart, "row.order")[rkeep],,drop=FALSE]
        xx <- xx[attr(ss$bestpart, "row.order")[rkeep],,drop=FALSE]
#        bp <- bp[ss$row.order[rkeep],,drop=FALSE]
#        xx <- xx[ss$row.order[rkeep],,drop=FALSE]
    }
    if (sort_c) {
        ## richness based ordering
        #corder <- order(-colSums(bp), colnames(bp))
        ## similarity based ordering
        ## (hard coding to avoid dependencies, not expecting too many columns)
        dm <- diag(1, ncol(bp), ncol(bp))
        for (i in seq_len(ncol(bp))) {
            for (j in i:ncol(bp)) {
                #dm[i,j] <- dm[j,i] <- sum(bp[,i] == bp[,j]) / nrow(bp) # (a + d) / n
                dm[i,j] <- dm[j,i] <- sum(bp[,i] * bp[,j]) / nrow(bp) # a / n
            }
        }
        corder <- hclust(as.dist(1 - dm), method = "ward.D2")$order # R (>= 3.1.0)
        bp <- bp[,corder,drop=FALSE]
        bp01 <- bp01[,corder,drop=FALSE]
    }
    n <- nrow(bp)
    p <- ncol(bp)
    Cols <- occolors(theme)(100)
    lower <- min(max(lower, 0), 1)
    op <- par(las=las, mar=mar)
    on.exit(par(op))
    if (horizontal) {
        plot(0, xlim=c(0, p), ylim=c(n, 0),
            type="n", axes=FALSE, ann=FALSE, ...)
        title(ylab=ylab, xlab=xlab)
        axis(1, at=seq_len(p)-0.5, lwd=0, lwd.ticks=1,
            labels=colnames(bp), tick=tick, ...)
        axis(2, at=seq_len(n)-0.5, lwd=0, lwd.ticks=1,
            labels=rownames(bp), tick=tick, ...)
        if (show_S)
            axis(3, at=seq_len(ncol(bp))-0.5,
                labels=colSums(bp01), tick=FALSE, ...)
        if (show_I)
            axis(4, at=seq_len(n)-0.5,
                labels=format(round(xx$I, 2), nsmall=2), tick=FALSE, ...)
        if (hr)
            abline(h=1:n-0.5, col=Cols[1L], lwd=0.45)
    } else {
        plot(0, ylim=c(0, p), xlim=c(n, 0),
            type="n", axes=FALSE, ann=FALSE, ...)
        title(ylab=xlab, xlab=ylab)
        axis(2, at=seq_len(p)-0.5, lwd=0, lwd.ticks=1,
            labels=colnames(bp), tick=tick, ...)
        axis(1, at=seq_len(n)-0.5, lwd=0, lwd.ticks=1,
            labels=rownames(bp), tick=tick, ...)
        if (show_S)
            axis(4, at=seq_len(ncol(bp))-0.5,
                labels=colSums(bp01), tick=FALSE, ...)
        if (show_I)
            axis(3, at=seq_len(n)-0.5,
                labels=format(round(xx$I, 2), nsmall=2), tick=FALSE, ...)
        if (hr)
            abline(v=1:n-0.5, col=Cols[1L], lwd=0.45)
    }
    for (i in seq_len(n)) {
        for (j in seq_len(p)) {

            Max <- 0.5*xx$I[i]+0.5
            Min <- 0.5*(1-xx$I[i])
            h0 <- bp[i,j] * (Max - Min) + Min

#            h0 <- if (bp[i,j] == 1)
#                0.5*xx$I[i]+0.5 else 0.5*(1-xx$I[i])

#            h0 <- bp[i,j]

            ## need to tweak the 50/50 to be higher than 0
            ## which is rare for logLR > 2 species
            h <- h0 * c(1 - lower) + lower
            ColID <- as.integer(pmin(pmax(1, floor(h0 * 100) + 1), 100))
            adj <- h * -pos
            if (horizontal) {
                polygon(
                    c(0, 1, 1, 0) + j - 1,
                    upper * 0.5 * (adj + c(-h, -h, h, h)) + i - 0.5,
                    col=Cols[ColID], border=Cols[ColID], lwd=0.5)
            } else {
                polygon(
                    upper * 0.5 * (adj + c(-h, -h, h, h)) + i - 0.5,
                    c(0, 1, 1, 0) + j - 1,
                    col=Cols[ColID], border=Cols[ColID], lwd=0.5)
            }
        }
    }
    box(col="grey", bty=bty)
    invisible(list(summary=xx, bestpart=bp01, mu=bp))
}

