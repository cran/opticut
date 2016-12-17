\name{lorenz}
\alias{lorenz}
\alias{summary.lorenz}
\alias{print.summary.lorenz}
\alias{quantile.lorenz}
\alias{plot.lorenz}
\title{
Lorenz curve bases thresholds and partitions
}
\description{
Lorenz curve bases thresholds and partitions.
}
\usage{
lorenz(x, na.last = TRUE)

\method{quantile}{lorenz}(x, probs = seq(0, 1, 0.25), ...)
\method{plot}{lorenz}(x, type = c("L", "x"),
    tangent = NA, h = NA, v = NA, ...)

\method{print}{summary.lorenz}(x, digits, ...)
\method{summary}{lorenz}(object, ...)
}
\arguments{
  \item{x}{a vector of nonnegative numbers for \code{lorenz}, or
an object to plot or summarized.
}
  \item{na.last}{for controlling the treatment of \code{NA}s.
If \code{TRUE}, missing values in the data are put last;
if \code{FALSE}, they are put first; if \code{NA}, they are removed
(see \code{\link{order}}).
}
  \item{probs}{numeric vector of probabilities with values in [0,1],
as in \code{\link{quantile}}.
}
  \item{type}{character, indicating what to plot. \code{"L"}: the cumulative
distribution quantiles; \code{"x"}: ordered but not-cumulated values.
}
  \item{tangent}{
color value for the Lorenz-curve tangent when plotted. The default
\code{NA} value omits the tangent from the plot.
}
  \item{h}{
color value for the horizontal line for the Lorenz-curve tangent
when plotted. The default
\code{NA} value omits the horizontal line from the plot.
}
  \item{v}{
color value for the vertical line for the Lorenz-curve tangent
when plotted. The default
\code{NA} value omits the vertical line from the plot.
}
  \item{digits}{
numeric, number of significant digits in output.
}
  \item{object}{
object to summarize.
}
  \item{\dots}{
other arguments passed to the underlying functions.
}
}
\details{
The Lorenz curve is a continuous piecewise linear function
representing the distribution of income or wealth.
Cumulative portion of the population: p_i = 1 / n (i=1,...,n), vs.
cumulative portion of wealth: L_i = sum_{j=1}^{i} x_j / sum_{j=1}^{n} x_j,
where x_i are indexed in non-decreasing order (x_i <= x_{i+1}).
By convention, p_0 = L_0 = 0.

The following charactersitics of the Lorenz curve are calculated:
\code{"t"}: index where tangent (slope 1) touches the curve;
\code{"x(t)"}, \code{"p(t)"}, and \code{"L(t)"} are values corresponding to
index t.
\code{"S"}: Lorenz asymmetry coefficient (S = p(t) + L(t)),
S = 1 indicates symmetry.
\code{"G"}: Gini coefficient. 0 is perfect equality,
  values close to 1 indicate high inequality.
\code{"J"}: Youden index is the (largest) distance between the anti-diagonal
and the curve. Distance is largest at the tangent point
(J = max(p(t) - L(t))).
}
\value{
\code{lorenz} returns an object of class lorenz. It is a matrix with n+1 rows
(n = \code{length(x)}) and 3 columns (p, L, x).

The \code{quantile} method finds values of x_i corresponding to quantiles p_i.
The \code{plot} method draws a Lorenz curve.
The \code{summary} method returns characteristics of the Lorenz curve.
}
\references{
Damgaard, C., & Weiner, J. (2000):
Describing inequality in plant size or fecundity.
Ecology 81:1139--1142.
<doi:10.2307/177185>

Schisterman, E. F., Perkins, N. J., Liu, A., & Bondell, H. (2005):
Optimal cut-point and its corresponding Youden index
to discriminate individuals using pooled blood samples.
Epidemiology 16:73--81.
<doi:10.1097/01.ede.0000147512.81966.ba>

Youden, W. J. (1950):
Index for rating diagnostic tests.
Cancer 3:32--5.
<doi:10.1002/1097-0142(1950)3:1<32::AID-CNCR2820030106>3.0.CO;2-3>
}
\author{
Peter Solymos <solymos@ualberta.ca>
}
\seealso{
\code{\link{quantile}}, \code{\link{order}}.
}
\examples{
set.seed(1)
x <- c(rexp(100, 10), rexp(200, 1))

l <- lorenz(x)
head(l)
tail(l)
summary(l)

op <- par(mfrow=c(2,1))
plot(l, lwd=2, tangent=2, h=3, v=4)
abline(0, 1, lty=2, col="grey")
abline(1, -1, lty=2, col="grey")
plot(l, type="x", lwd=2, h=3, v=4)
par(op)
}
\keyword{ manip }
\keyword{ misc }