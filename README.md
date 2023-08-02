
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ineptR <a href="https://c-matos.github.io/ineptR/"><img src="man/figures/logo.png" align="right" height="132" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/c-matos/ineptR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/c-matos/ineptR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview

The goal of ineptR is to facilitate and automate data extraction from
Statistics Portugal (Instituto Nacional de Estatistica - INE, PT) with
R.  
It consists mainly of wrapper functions around the [INE
API](https://www.ine.pt/xportal/xmain?xpid=INE&xpgid=ine_api&INST=322751522),
and some helper functions to inspect metadata.  
One limitation of the INE API is that data extraction is limited to 40k
data points in each API call. For convenience, this package deals with
that limitation internally, and the user can get all the records in a
single `get_ine_data()` function call.

For a basic usage example, keep reading.  
For more in-depth examples, check `vignette("use_cases")`.

## Installation

You can install the development version of ineptR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("c-matos/ineptR")
```

## Usage

This is a basic workflow to inspect and get data from INE.

``` r
#Load package
library(ineptR)
```

1.  Navigate to the INE website and identify the desired indicador ID.

- Example: [Proportion of domestic budget funded by domestic taxes (%);
  Annual](https://www.ine.pt/xportal/xmain?xpid=INE&xpgid=ine_indicadores&indOcorrCod=0010003&contexto=bd&selTab=tab2&xlang=pt.)
- Get the indicator ID from the indOcorrCod query parameter in the URL.
  In this case the ID is ***001003***

2.  Confirm that the indicator ID is valid:

``` r
#Check if indicator is valid
is_indicator_valid("0010003")
#> [1] TRUE
```

3.  Inspect metadata:

``` r
get_metadata("0010003")
#> $IndicadorCod
#> [1] "0010003"
#> 
#> $IndicadorNome
#> [1] "Percentagem do orçamento de Estado financiado por impostos cobrados internamente (%); Anual - Direção Geral do Orçamento (Ministério das Finanças)"
#> 
#> $Periodic
#> [1] "Anual"
#> 
#> $PrimeiroPeriodo
#> [1] "2010"
#> 
#> $UltimoPeriodo
#> [1] "2023"
#> 
#> $UnidadeMedida
#> [1] "Percentagem (%)"
#> 
#> $Potencia10
#> [1] "0"
#> 
#> $PrecisaoDecimal
#> [1] "2"
#> 
#> $Lingua
#> [1] "PT"
#> 
#> $DataUltimaAtualizacao
#> [1] "2022-12-28"
#> 
#> $DataExtracao
#> [1] "2023-08-02T17:10:46.383+01:00"
```

4.  Get information about the dimensions:

- How many dimensions are in this indicator and what are they?

``` r
get_dim_info("0010003")
#> # A tibble: 2 × 3
#>   dim_num abrv                            versao
#>   <chr>   <chr>                           <chr> 
#> 1 1       Período de referência dos dados XXXXX 
#> 2 2       Localização geográfica          03505
```

- What are the unique values for each dimension?

``` r
get_dim_values("0010003")
#> # A tibble: 15 × 7
#>    dim_num cat_id  categ_cod categ_dsg categ_ord categ_nivel value_id        
#>    <chr>   <chr>   <chr>     <chr>     <chr>     <chr>       <chr>           
#>  1 1       S7A2010 S7A2010   2010      20100101  1           Dim_Num1_S7A2010
#>  2 1       S7A2011 S7A2011   2011      20110101  1           Dim_Num1_S7A2011
#>  3 1       S7A2012 S7A2012   2012      20120101  1           Dim_Num1_S7A2012
#>  4 1       S7A2013 S7A2013   2013      20130101  1           Dim_Num1_S7A2013
#>  5 1       S7A2014 S7A2014   2014      20140101  1           Dim_Num1_S7A2014
#>  6 1       S7A2015 S7A2015   2015      20150101  1           Dim_Num1_S7A2015
#>  7 1       S7A2016 S7A2016   2016      20160101  1           Dim_Num1_S7A2016
#>  8 1       S7A2017 S7A2017   2017      20170101  1           Dim_Num1_S7A2017
#>  9 1       S7A2018 S7A2018   2018      20180101  1           Dim_Num1_S7A2018
#> 10 1       S7A2019 S7A2019   2019      20190101  1           Dim_Num1_S7A2019
#> 11 1       S7A2020 S7A2020   2020      20200101  1           Dim_Num1_S7A2020
#> 12 1       S7A2021 S7A2021   2021      20210101  1           Dim_Num1_S7A2021
#> 13 1       S7A2022 S7A2022   2022      20220101  1           Dim_Num1_S7A2022
#> 14 1       S7A2023 S7A2023   2023      20230101  1           Dim_Num1_S7A2023
#> 15 2       PT      PT        Portugal  1         1           Dim_Num2_PT
```

5.  Get the data:

``` r
get_ine_data("0010003")
#>    dim_1 geocod   geodsg valor
#> 1   2010     PT Portugal 58.31
#> 2   2011     PT Portugal 60.04
#> 3   2012     PT Portugal 60.53
#> 4   2013     PT Portugal 58.92
#> 5   2014     PT Portugal  62.1
#> 6   2015     PT Portugal 61.28
#> 7   2016     PT Portugal 64.61
#> 8   2017     PT Portugal 64.55
#> 9   2018     PT Portugal 67.41
#> 10  2019     PT Portugal 69.16
#> 11  2020     PT Portugal 58.01
#> 12  2021     PT Portugal 60.72
#> 13  2022     PT Portugal 64.18
#> 14  2023     PT Portugal 66.08
```
