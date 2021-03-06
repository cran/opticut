## internal wrapper to do single species
.uncertaintyOpticut1 <-
function (object, which=NULL,
type=c("asymp", "boot", "multi"), B=99, pb=FALSE, ...)
{
    dots <- setdiff(names(object$call)[-1L],
        c("X", "Y", "formula", "data", "strata", "dist", "comb", "sset", "cl"))
    if (length(dots) > 0)
        stop("Extra arguments detected in opticut call (...)")
    type <- match.arg(type)
    if (missing(which))
        stop("specify which argument")
    if (!length(which))
        stop("which argument must have length 1")
    linkinv <- .get_linkinv(object, ...)
    scale <- object$scale
    obj <- object$species[[which]]
    n <- nobs(object)
    k <- which.max(obj$logLR)
    if (type == "asymp") {
        if (length(B) > 1)
            stop("Provide single integer for B.")
        niter <- B
        bm <- rownames(obj)[k]
        mle <- getMLE(object, which, vcov=TRUE, ...)
        if (!is.function(object$dist) &&
            .opticut_dist(object$dist, make_dist=TRUE) == "rsf") {
            cf <- MASS::mvrnorm(niter, mle$coef[-1L],
                mle$vcov[-1L,-1L,drop=FALSE])
            cf <- rbind(mle$coef[c(1L, 2L)], cbind(0, cf)[,c(1L, 2L)])
        } else {
            cf <- MASS::mvrnorm(niter, mle$coef, mle$vcov)
            cf <- rbind(mle$coef[c(1L, 2L)], cf[,c(1L, 2L)])
        }
        cf0 <- linkinv(cf[,1L])
        cf1 <- linkinv(cf[,1L] + cf[,2L])
        I <- abs(tanh(cf[,2L] * scale))
        out <- data.frame(best=bm, I=I, mu0=cf0, mu1=cf1) # opticut1
    } else {
        if (length(B) == 1) {
            niter <- B
            ## RSF/RSPF requires only used points to be resampled
            if (!is.function(object$dist) &&
                .opticut_dist(object$dist, make_dist=TRUE) %in% c("rsf", "rspf")) {
                avail <- which(object$Y[,1]==0)
                used <- which(object$Y[,1]==1)
                nused <- length(used)
                BB <- replicate(niter, c(sample(used, nused, replace=TRUE), avail))
            } else {
                BB <- replicate(niter, sample.int(n, replace=TRUE))
            }
        } else {
            BB <- B
            niter <- ncol(B)
        }
        nstr <- check_strata(object, BB)
        if (!all(nstr))
            stop("Not all strata represented in resampling")
    }
    if (type == "boot") {
        bm <- rownames(obj)[k]
        m1 <- .extractOpticut(object, which,
            boot=FALSE,
            internal=TRUE,
            full_model=FALSE,
            best=TRUE, ...)[[1L]]
        cf <- if (pb) {
            t(pbapply::pbapply(BB, 2, function(z, ...) {
                .extractOpticut(object, which,
                    boot=z,
                    internal=TRUE,
                    full_model=FALSE,
                    best=TRUE, ...)[[1L]]$coef[c(1L, 2L)]
            }))
        } else {
            t(apply(BB, 2, function(z, ...) {
                .extractOpticut(object, which,
                    boot=z,
                    internal=TRUE,
                    full_model=FALSE,
                    best=TRUE, ...)[[1L]]$coef[c(1L, 2L)]
            }))
        }
        #cf <- rbind(coef(m1)[c(1L, 2L)], cf)
        cf <- rbind(m1$coef[c(1L, 2L)], cf)
        cf0 <- linkinv(cf[,1L])
        cf1 <- linkinv(cf[,1L] + cf[,2L])
        I <- abs(tanh(cf[,2L] * scale))
        out <- data.frame(best=bm, I=I, mu0=cf0, mu1=cf1)
    }
    if (type == "multi") {
        bm <- character(niter + 1L)
        bm[1L] <- rownames(obj)[k]
        mat <- matrix(NA, niter + 1L, 3)
        colnames(mat) <- c("I", "mu0", "mu1")
        tmp <- as.numeric(obj[k, -1L])
        names(tmp) <- colnames(obj)[-1L]
        mat[1L, ] <- tmp[c("I", "mu0", "mu1")]
        if (pb) {
            pbar <- pbapply::startpb(0, niter)
            on.exit(pbapply::closepb(pbar), add=TRUE)
        }
        for (j in seq_len(niter)) {
            ## Z is factor, thus 'rank' applied
            mod <- .extractOpticut(object, which,
                boot=BB[,j],
                internal=FALSE,
                best=FALSE, ...)[[1L]]
            k <- which.max(mod$logLR)
            bm[j + 1L] <- rownames(mod)[k]
            tmp <- as.numeric(mod[k, -1L])
            names(tmp) <- colnames(mod)[-1L]
            mat[j + 1L, ] <- tmp[c("I", "mu0", "mu1")]
            if (pb)
                pbapply::setpb(pbar, j)
        }
        out <- data.frame(best=bm, mat)
        attr(out, "est") <- attr(obj, "est")
    }
    class(out) <- c("uncertainty1_opti", "uncertainty1", "data.frame")
    attr(out, "B") <- niter
    attr(out, "type") <- type
    attr(out, "scale") <- scale
    attr(out, "collapse") <- object$collapse
    out
}
