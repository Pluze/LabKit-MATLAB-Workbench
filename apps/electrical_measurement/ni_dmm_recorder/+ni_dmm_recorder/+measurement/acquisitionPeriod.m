function [period_s, limited] = acquisitionPeriod(requestedRate_Hz, measurementPeriod_s)
%ACQUISITIONPERIOD Reconcile requested pacing with measured device capability.
if ~(isnumeric(requestedRate_Hz) && isscalar(requestedRate_Hz) && ...
        isfinite(requestedRate_Hz) && requestedRate_Hz > 0)
    error("ni_dmm_recorder:InvalidRate", ...
        "Requested acquisition rate must be a positive finite scalar.");
end
if ~(isnumeric(measurementPeriod_s) && isscalar(measurementPeriod_s) && ...
        isfinite(measurementPeriod_s) && measurementPeriod_s > 0)
    error("ni_dmm_recorder:InvalidMeasurementPeriod", ...
        "NI-DMM measurement period must be a positive finite scalar.");
end
requestedPeriod_s = 1 / double(requestedRate_Hz);
period_s = max(requestedPeriod_s, double(measurementPeriod_s));
limited = period_s > requestedPeriod_s;
end
