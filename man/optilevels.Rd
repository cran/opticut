\name{optilevels}
\alias{optilevels}
\alias{bestmodel.optilevels}
\title{
Optimal Number of Factor Levels
}
\description{
Finds the optimal number of factor levels given the data and a model
using a likelihood-based agglomerative algorithm.
}
\usage{
optilevels(y, x, z = NULL, alpha = 0, dist = "gaussian", ...)

\method{bestmodel}{optilevels}(object, ...)
}
\arguments{
  \item{y}{
vector of observations.
}
  \item{x}{
a factor or a matrix of proportions (i.e. the values 0 and 1 should have
consistent meaning across the columns, often through a unit sum constraint).
It is the user's responsibility to ensure that values supplied
for \code{x} are sensible. \code{x} is not expected to
include an intercept.
}
  \item{z}{
a design matrix with predictor variables besides the one(s) defined
via the argument \code{x}.
It is the user's responsibility to ensure that values supplied
for \code{z} are sensible and it also makes sense to bind
\code{x} and \code{z} together.
Variables in \code{z} should be centered (mean 0) (and
possibly normalized by SD), because the design matrix
from \code{x} is not expected to include an intercept.
}
  \item{alpha}{numeric [0-1],
weighting factor for calculating information criteria for model selection
(i.e. IC = (1-alpha)*AIC + alpha*BIC, also referred to as CAIC: consistent AIC).
}
  \item{dist}{
character, distribution argument passed to underlying functions,
see listed on the help page of \code{\link{opticut}}
(except for \code{dist = "zip2"}, \code{dist = "zinb2"}
\code{dist = "rsf"}, and \code{dist = "rspf"}).
}
  \item{object}{
fitted object.
}
  \item{\dots}{
other arguments passed to the underlying functions, see \code{\link{opticut1}}.
}
}
\value{
An object of class 'optilevels' that is a list with the following elements:

\describe{
\item{\code{"delta"}}{delta IC values along the selection path considering best models.}

\item{\code{"ic"}}{IC values along the selection path considering best models.}

\item{\code{"coef"}}{matrix of coefficients (linear predictor scale)
corresponding to argument \code{x}
along the selection path considering best models.}

\item{\code{"zcoef"}}{matrix of coefficients (linear predictor scale)
corresponding to argument \code{z} when not \code{NULL}
along the selection path considering best models, or \code{NULL}.}

\item{\code{"rank"}}{matrix ranks based on the coefficients
along the selection path considering best models.
Ranking uses the default \code{ties.method = "average"} in \code{\link{rank}}.}

\item{\code{"deltalist"}}{delta IC values along the selection path
considering all competing models.}

\item{\code{"iclist"}}{IC values along the selection path
considering all competing models.}

\item{\code{"coeflist"}}{matrix of coefficients (linear predictor scale)
corresponding to argument \code{x}
along the selection path considering all competing models.}

\item{\code{"zcoeflist"}}{matrix of coefficients (linear predictor scale)
corresponding to argument \code{z} when not \code{NULL}
along the selection path considering all competing models, or \code{NULL}.}

\item{\code{"ranklist"}}{matrix ranks based on the coefficients
along the selection path considering all competing models.}

\item{\code{"levels"}}{list of (merged) factor levels along the selection path
considering best models.}

\item{\code{"Y"}}{vector of observations (argument \code{y}).}

\item{\code{"X"}}{design matrix component corresponding to argument \code{x}.}

\item{\code{"Z"}}{design matrix component corresponding to argument \code{z}.}

\item{\code{"alpha"}}{weighting argument.}

\item{\code{"dist"}}{distribution argument.}

\item{\code{"factor"}}{logical, indicating if argument \code{x} is a factor
(\code{TRUE}) or a matrix (\code{FALSE}).}
}

\code{bestmodel} returns the best supported model for further
manipulation (e.g. prediction).
}
\author{
Peter Solymos <psolymos@gmail.com>
}
\seealso{
\code{\link{opticut}} and \code{\link{multicut}}
for fitting best binary and multi-level response models.
}
\examples{
## --- Factor levels with Gaussian distribution
## simple example from Legendre 2013
## Indicator Species: Computation, in
## Encyclopedia of Biodiversity, Volume 4
## https://dx.doi.org/10.1016/B978-0-12-384719-5.00430-5
gr <- as.factor(paste0("X", rep(1:5, each=5)))
spp <- cbind(Species1=rep(c(4,6,5,3,2), each=5),
    Species2=c(rep(c(8,4,6), each=5), 4,4,2, rep(0,7)),
    Species3=rep(c(18,2,0,0,0), each=5))
rownames(spp) <- gr
## must add some noise to avoid perfect fit
spp[6, "Species1"] <- 7
spp[1, "Species3"] <- 17
spp

ol <- optilevels(spp[,"Species3"], gr)
ol[c("delta", "coef", "rank", "levels")]

## get the final factor level
gr1 <- gr
levels(gr1) <- ol$level[[length(ol$level)]]
table(gr, gr1)

## compare the models
o0 <- lm(spp[,"Species3"] ~ gr - 1)
o1 <- lm(spp[,"Species3"] ~ gr1 - 1)
data.frame(AIC(o0, o1), delta=AIC(o0, o1)$AIC - AIC(o0))
ol$delta # should be identical

## --- Proportions with Poisson distribution
## simulation
set.seed(123)
n <- 500 # number of observations
k <- 5 # number of habitat types
b <- c(-1, -0.2, -0.2, 0.5, 1)
names(b) <- LETTERS[1:k]
x <- replicate(k, exp(rnorm(n)))
x <- x / rowSums(x) # proportions
X <- model.matrix(~.-1, data=data.frame(x))
lam <- exp(drop(crossprod(t(X), b)))
y <- rpois(n, lam)

z <- optilevels(y, x, dist="poisson")

## best model refit
bestmodel(z)

## estimates
plogis(z$coef)
plogis(b)
## optimal classification
z$rank

## get the final matrix
x1 <- mefa4::groupSums(x, 2, z$levels[[length(z$levels)]])
head(x)
head(x1)

## compare the models
m0 <- glm(y ~ x - 1, family="poisson")
m1 <- glm(y ~ x1 - 1, family="poisson")
data.frame(AIC(m0, m1), delta=AIC(m0, m1)$AIC - AIC(m0))
z$delta # should be identical

\dontrun{
## dolina example with factor
data(dolina)
dolina$samp$stratum <- as.integer(dolina$samp$stratum)
y <- dolina$xtab[dolina$samp$method == "Q", "ppyg"]
x <- dolina$samp$mhab[dolina$samp$method == "Q"]
z <- scale(model.matrix(~ stratum + lmoist - 1,
    dolina$samp[dolina$samp$method == "Q",]))

## without additional covariates
dol1 <- optilevels(y, x, z=NULL, dist="poisson")
dol1$rank
summary(bestmodel(dol1))

## with additional covariates
dol2 <- optilevels(y, x, z, dist="poisson")
dol2$rank
summary(bestmodel(dol2))

## compare the two models
AIC(bestmodel(dol1), bestmodel(dol2))
}
}
\keyword{ manip }
\keyword{ models }
