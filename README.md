


# tamper

> Easier Debugging of `magrittr` Pipes

[![Linux Build Status](https://travis-ci.org/gaborcsardi/tamper.svg?branch=master)](https://travis-ci.org/gaborcsardi/tamper)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/github/gaborcsardi/tamper?svg=true)](https://ci.appveyor.com/project/gaborcsardi/tamper)
[![](http://www.r-pkg.org/badges/version/tamper)](http://www.r-pkg.org/pkg/tamper)
[![CRAN RStudio mirror downloads](http://cranlogs.r-pkg.org/badges/tamper)](http://www.r-pkg.org/pkg/tamper)


One difficulty of
[`magrittr`](https://github.com/smbache/magrittr) pipes is that they make
debugging harder. If you don't always write correct code, and you use
pipes, then you'll find `tamper` very useful. It is the `magrittr` specific
alternative of the `recover` function: when used with
`options(error = tamper)`, after an error it displays the whole pipeline,
marks the place of the error, and helps saving the temporary results. 

## Installation


```r
devtools::install_github("gaborcsardi/tamper")
```

## Usage

```r
options(error = tamper::tamper)
```

Then, if you make a mistake in a pipeline, instead of the standard
R stack trace, `tamper` is invoked and you can explore the data in
the pipeline, and also save to a temporary variable.

```r
library(magrittr)
1:10 %>%
  multiply_by(10) %>%
  add(10) %>%
  add("oh no!") %>%
  subtract(5) %>%
  divide_by(5)
```

You will see:

```r
Error in add(., "oh no!") : non-numeric argument to binary operator

Enter 0 to exit or choose:

1:    Switch mode
2:    Take me to the error

3:    1:10 %>%
4:      multiply_by(., 10) %>%
5:      add(., 10) %>%
6: ->   add(., "oh no!") %>%
7:      subtract(., 5) %>%
8:      divide_by(., 5)

Selection:
```

The stage with the error is clearly marged with an arrow. You can get to
the function in which the error happened with selecting `2`. (Unless it
is a primitive function, those are not in the call stack.)

If you select `6`, you can browse the frame that corresponds to the
pipeline stage in which the error happened: 

```r
Selection: 6
Called from: eval(substitute(expr), envir, enclos)
Browse[1]> ls()
[1] "function_list" "k"             "value"
```

`value` is the value of the `.` dot variable, at the beginning
of the pipeline stage:

```r
Browse[1]> value
[1]  20  30  40  50  60  70  80  90 100 110
```

If you don't want to redo the initial part of the pipeline, you
can save `value` to a global variable in your workspace:

```r
Browse[1]> assign("value", value, envir = globalenv())
```

## Feedback

Please see our
[issue tracker](https://github.com/gaborcsardi/tamper/issues).

## License

MIT © [Gábor Csárdi](https://github.com/gaborcsardi).
