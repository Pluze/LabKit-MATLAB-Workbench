function parameters = sanitizeParameters(parameters, ~)
%SANITIZEPARAMETERS Validate the ECGNExT analysis settings.
fields = ["roiStart","roiEnd","peakDistance"];
for field = fields
    value = parameters.(field);
    if ~isnumeric(value) || ~isscalar(value) || ~isreal(value) || ~isfinite(value)
        error('ecg_print:InvalidAnalysisSetting','Analysis settings must be finite scalars.');
    end
end
if parameters.roiStart < 0 || parameters.roiEnd < 0 || parameters.peakDistance <= .2
    error('ecg_print:InvalidAnalysisSetting','Use nonnegative ROI times and peak distance above 0.2 s.');
end
ecg_print.analysisRun.peakMethodValue(parameters.peakMethod);
end
