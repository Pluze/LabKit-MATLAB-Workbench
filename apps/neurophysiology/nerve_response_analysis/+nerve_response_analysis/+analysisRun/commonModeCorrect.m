% Expected caller: nerve_response_analysis.analysisRun.analyzeRecording or tests.
% Inputs are matched time, positive, negative, optional common-mode signal,
% and analysis options. Output is corrected differential signal.
function result = commonModeCorrect(timeSec, positive, negative, common, opts)
%COMMONMODECORRECT Apply differential and optional common-mode correction.

    if nargin < 5 || isempty(opts)
        opts = struct();
    end
    if nargin < 4
        common = [];
    end

    timeSec = double(timeSec(:));
    positive = double(positive(:));
    negative = double(negative(:));
    validateVectorSizes(timeSec, positive, negative);

    mode = string(fieldOrDefault(opts, "mode", "A-minus-B"));
    switch lower(regexprep(char(mode), "[^A-Za-z0-9]", ""))
        case {"bminusa", "negativeminuspositive"}
            raw = negative - positive;
        case {"common", "commononly"}
            raw = zeros(size(positive));
        otherwise
            raw = positive - negative;
    end

    gain = 0;
    baseline = 0;
    corrected = raw;
    if ~isempty(common)
        common = double(common(:));
        validateVectorSizes(timeSec, common);
        fitWindowFraction = double(fieldOrDefault(opts, ...
            "fitWindowFraction", 0.25));
        nFit = max(3, min(numel(timeSec), round(numel(timeSec) * ...
            fitWindowFraction)));
        x = common(1:nFit);
        y = raw(1:nFit);
        x = x - mean(x, "omitnan");
        y = y - mean(y, "omitnan");
        denom = sum(x .^ 2, "omitnan");
        if denom > 0
            gain = sum(x .* y, "omitnan") / denom;
        end
        baseline = mean(raw(1:nFit) - gain .* common(1:nFit), "omitnan");
        corrected = raw - baseline - gain .* common;
    end

    result = struct( ...
        "timeSec", timeSec, ...
        "raw", raw, ...
        "corrected", corrected, ...
        "gain", gain, ...
        "baseline", baseline, ...
        "mode", mode);
end

function validateVectorSizes(varargin)
    n = numel(varargin{1});
    for k = 2:nargin
        if numel(varargin{k}) ~= n
            error("nerve_response_analysis:CommonModeSizeMismatch", ...
                "Common-mode vectors must have matching lengths.");
        end
    end
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end
