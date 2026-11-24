function count = sampleCount(seconds, fs)
% Round one common duration to the nearest whole sample for both ROIs.
    count = round(seconds * fs);
    if ~isscalar(count) || ~isfinite(count) || count < 2
        error("emg_review:InvalidWindow", "Set a window duration of at least two samples.");
    end
end
