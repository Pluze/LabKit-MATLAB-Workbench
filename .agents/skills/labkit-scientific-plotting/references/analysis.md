# Analysis decisions for scientific plots

## Groups, uncertainty, and limits

Preserve sample and condition identifiers when joining. Distinguish independent specimens, repeated observations within specimens, and paired measurements. For small groups, show observations with the appropriate summary. Use a raw-point overlay with a boxplot only when its quartiles and sample count are meaningful. Use sample SD for observed spread or a justified interval for an estimate. Label the statistic, the aggregation level, and the independent sample count. Connect the same subject or specimen across conditions when the pairing is relevant.

Show instrument over-range and below-detection values as bounds. Use a marker or arrow at the limit with the inequality and the censored count when useful. Keep the bound out of ordinary means or fits unless a justified censoring method is used. Break curves across missing observations. State any treatment of invalid log-scale values.

## Trends, mechanism, and estimates

Keep measured points visible. Choose a fit that matches the question and observation process. To compare competing models, use the same response scale, observations, and comparable weighting. Inspect residuals and state the fitting range, objective and any support for extrapolation. A fit to grouped means needs a description of how they were formed and weighted. Keep interpolation and physical mechanism separate, especially with few predictor levels.

For a calculated scenario, give the equation, units, parameter sources, geometry or other material assumptions, and valid domain. Keep reference data and scenarios distinct from experimental outcomes. For a ratio or change, name the denominator and match conditions, units, or time points before computing it. Keep normalized comparisons traceable to absolute values.

## Signals, regions of interest, and spectra

Confirm channel, units, sample clock or timestamps, acquisition filters and saturation limits. Document additional filtering and its edge treatment. Retain a waveform overview so large excursions or excluded intervals remain visible. Use matched windows and consistent scales where the comparison requires them. Choose region-of-interest (ROI) windows from protocol markers or a stated rule that can be applied across recordings. Label manually selected diagnostic examples and keep them out of inferential summaries when appropriate. Mark the exact time bounds and pair identifiers, preserve sample counts, and keep display resampling separate from calculation.

Define signal and background before calculating SNR. A raw active-to-background RMS contrast is `20 log10(RMS_active / RMS_background)`. For an additive, uncorrelated background with comparable power in both windows, a noise-subtracted estimate instead uses `10 log10((P_active - P_background) / P_background)`. Mark cases without a reliable baseline or positive net power as unavailable. Avoid comparisons across unequated acquisition bands unless explicitly described as diagnostic.

For a spectrum, state the analysis band, window duration, taper, detrending, normalization, one- or two-sided convention, and averaging. Give the frequency resolution and PSD units or dB reference. Average linear power before converting to dB when producing a mean PSD. Use matching frequency and power limits for comparisons. Show a full band and a zoom for a suspected narrow feature, and integrate over defined bins to quantify its contribution. Keep observed harmonics and candidate mechanisms distinct.

## Impedance and paired physical curves

Keep source impedance complex and source frequency in Hz. Use positive frequencies for logarithmic Bode plots and convert both magnitudes and uncertainty consistently. Match device, condition, and frequency before comparison. Show phase or the complex plane when the claim depends on mechanism. If fitting a complex model, document its frequency range, residual weighting, bounds, and checks for parameter-bound hits and residual structure. Preserve acquired timestamps and gaps when integrating or aligning paired signals.
