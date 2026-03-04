# extrapolateATT (development version)

## Major Features

### Multi-Method First-Stage Support (2026-03-04)

* **Full converter support** for three additional DiD methods:
  - `didimputation` (Borusyak, Jaravel, & Spiess 2021) - Imputation-based DiD
  - `did2s` (Gardner 2022) - Two-stage DiD
  - `DIDmultiplegt` (De Chaisemartin & d'Haultfoeuille 2020) - Multiple periods DiD

* **All major DiD methods now supported** with dedicated converters (5 total):
  - Callaway & Sant'Anna (`did::att_gt`)
  - Sun & Abraham (`fixest::sunab`)
  - Borusyak et al. (`didimputation::did_imputation`)
  - Gardner (`did2s::did2s`)
  - De Chaisemartin & d'Haultfoeuille (`DIDmultiplegt::did_multiplegt`)

* **Event-study to (cohort, time) mapping**: All converters handle single and multiple cohort scenarios via `cohort_timing` parameter

* **Comprehensive test coverage**: +91 new tests (449 total passing)

## Bug Fixes

* Fixed R regex patterns for cross-platform compatibility - use `[0-9]` instead of `\d` which is not recognized by R's regex engine (#1)

* Fixed mock test objects to properly support `stats::coef()` extraction

## Documentation

* Added usage examples for all 5 DiD methods in README
* Updated method status table (all methods now show "✅ Full support")
* Comprehensive roxygen documentation for all converters

## Internal

* Refactored to full tidyverse patterns for consistency
* Added session logging for multi-method implementation
