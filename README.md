# Real-time forecast of temperature-related excess mortality at small-area level

A illustration of the development of an operational framework for the forecast of excess mortality at small-area level, using a real-data case-study estimating the impact of the July 2022 heatwave in England and Wales

------------------------------------------------------------------------

This repository stores the updated R code and data to reproduce the analysis of the case study presented in the article:

Mistry MN, Gasparrini A. Real-time forecast of temperature-related excess mortality at small-area level: towards an operational framework. *Environmental Research: Health*. 2024;2:035011. DOI: 10.1088/2752-5309/ad5f51. [[freely available here](https://doi.org/10.1088/2752-5309/ad5f51)]

This work was supported by the Medical Research Council UK (Grant ID: MR/V034162/1) and the European Commission (H2020-MSCA-IF-2020) under REA grant agreement no. 101022870. 

### Data

The case study presents an analysis on the excess deaths during the July 2022 heatwave over England and Wales, estimated for each of the 34,753 lower layer super-output areas (LSOAs, a small-area census-based definition) and then aggregated at higher geographical units, age groups, and single days. The estimation of excess deaths is based on local age-specific risk functions obtained in previous work (Gasparrini et al. *The Lancet Planetary Health*. 2022;6:e557–e564. DOI: 10.1016/S2542-5196(22)00138-3 [[freely available here](http://www.ag-myresearch.com/2022_gasparrini_lancetplanhealth.html)]). These LSOA-specific risk functions were matched with gridded forecasts of sub-daily mean temperature available from the European Centre for Medium-Range Weather Forecasts (ECMWF) [[link](https://github.com/ecmwf/ecmwf-opendata)] and baseline population and mortality rates retrieved from National Online Manpower Information Service (NOMIS) - Official Labour Market Statistics [[link](https://www.nomisweb.co.uk/)]. Specific references and additional details are provided in the article.

The sub-folder *data* includes a series of files listed below. These files contain data and parameters of the original small-area analysis on temperature-mortality associations that are used here to quantify the excess deaths during the July 2022 heatwave. Details on the study design and statistical methods are provided in the article. The files:

-  *tmeanfcast.zip*: zipped dataset with the daily mean temperature forecasted for the days 17-22 July 2022 obtained by ECMWF, and extracted from their original gridded format to each LSOA by area-weighted averaging (see the section below about Python code).
-  *population_2020.zip* and *deathrates_2022.zip*: age-specific population distribution for 2020 at LSOA level and mortality rates for 2022 at regional level obtained from NOMIS.
-  *lookup.zip*: zipped dataset containing the lookup table between LSOAs and regions.
-  *coefmeta.RDS* and *vcovmeta.RDS*: coefficients and related (co)variance matrix of the second-stage meta-analytical model used in the original analysis by Gasparrini et al (see reference above) to predict the LSOA and age-specific risk functions.
-  *lsoatmeanper.RDS*, *lsoammtmmp.RDS*, and *lsoacomp.RDS*: LSOA-specific temperature percentiles, estimated minimum mortality temperature and related percentile (MMT and MMP), and values of principal component vulnerability factors. This information is used to reconstruct LSOA and age-specific risk functions.
-  *lsoashp.zip* and *ladshp.zip*: zipped shapefiles representing the geographical boundaries of LSOAs and local authority districs (LADs).

### R code

The four R scripts reproduces all the parts of the forecast analysis and the full results. Details are provided in the article, with comments throughout the scripts describing the specific steps. The scripts:

-   *00.pkg.R* loads the packages.
-   *01.prep.R* loads the datasets and links/assembles them in the right format.
-   *02.fcastcomp.R* performs the forecast computation by looping across LSOAs, specifically: 1) recostructing the design matrix to recover the coefficient/(co)variance matrix of the risk function; 2) calculating the excess mortality in the heatwave days; 3) aggregating accordingly, also computing and adding (empirical) confidence intervals.
-   *03.tables.R* produces the table included in the article with the main aggregated figures.
-   *04.maps.R* produces the maps included in the article, in particular the one illustrating the geographical and temporal distribution of excess deaths.

### Python code

The sub-folder *download* provides the Jupiter Notebook script *download_ecmwf_forecast.ipynb* with the Python code to download the gridded temperature forecast data. Note that the code offers an example to retrieve data for the corresponding days (17-22 July) in 2024 at 0.25 degrees, as the original database at 0.4 degrees for 2022 is not available anymore. Some documentation and specific details are provided in the pdf document in the same sub-folder.
