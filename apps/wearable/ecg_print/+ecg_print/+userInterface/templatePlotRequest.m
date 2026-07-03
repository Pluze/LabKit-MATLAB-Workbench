% Expected caller: ecg_print.userInterface.updateWorkbenchFromState and direct unit tests. Inputs are ECG
% segment/template/measurement structs plus the selected template view label.
% Output is a GUI-free plot request struct; no UI handles are read or mutated.

function request = templatePlotRequest(segments, template, measurements, viewLabel)
%TEMPLATEPLOTREQUEST Prepare ECG Print template plot data.

    request = struct( ...
        'ok', false, ...
        'title', 'Template + Residual Band', ...
        'xLabel', 'Time from peak (s)', ...
        'yLabel', 'Amplitude', ...
        'showSegments', false, ...
        'timeOffset', [], ...
        'segments', [], ...
        'showIndex', [], ...
        'template', [], ...
        'upper', [], ...
        'lower', [], ...
        'signalWindowSec', [], ...
        'noiseWindowsSec', []);

    if isempty(segments) || isempty(template) || isempty(segments.values)
        return;
    end

    X = double(segments.values);
    t = double(segments.timeOffset(:));
    templateValues = double(template.values(:));
    if isempty(X) || isempty(templateValues)
        return;
    end

    request.ok = true;
    request.timeOffset = t;
    request.segments = X;
    request.template = templateValues;

    if strcmp(viewLabel, 'Template + segments')
        maxShow = min(40, size(X, 2));
        request.showIndex = unique(round(linspace(1, size(X, 2), maxShow)));
        request.showSegments = true;
        request.title = 'Template + Segments';
    else
        residStd = std(X - templateValues, 0, 2, 'omitnan');
        request.upper = templateValues + residStd;
        request.lower = templateValues - residStd;
        request = addMeasurementWindows(request, measurements);
    end
end

function request = addMeasurementWindows(request, measurements)
    if isempty(measurements) || ~isfield(measurements, 'metadata')
        return;
    end
    meta = measurements.metadata;
    if ~isfield(meta, 'signalWindowSec') || ~isfield(meta, 'noiseWindowsSec')
        return;
    end
    request.signalWindowSec = meta.signalWindowSec;
    request.noiseWindowsSec = meta.noiseWindowsSec;
end
