% Expected caller: ecg_print.workbench.present and direct unit tests. Inputs
% are ECG segment/template/measurement structs and the signal unit. Output is
% a pair of GUI-free requests for simultaneous template views.
function requests = templatePlotRequests(segments, template, measurements, unit)
%TEMPLATEPLOTREQUESTS Prepare residual-band and segment-overlay plot data.
empty = struct( ...
    'ok', false, ...
    'title', '', ...
    'xLabel', 'Time from peak (s)', ...
    'yLabel', char("Amplitude (" + string(unit) + ")"), ...
    'showSegments', false, ...
    'timeOffset', [], ...
    'segments', [], ...
    'showIndex', [], ...
    'template', [], ...
    'upper', [], ...
    'lower', [], ...
    'signalWindowSec', [], ...
    'noiseWindowsSec', []);
requests = repmat(empty, 1, 2);
requests(1).title = 'Residual band';
requests(2).title = 'Segment overlay';
requests(2).showSegments = true;

if isempty(segments) || isempty(template) || isempty(segments.values)
    return;
end

X = double(segments.values);
t = double(segments.timeOffset(:));
templateValues = double(template.values(:));
if isempty(X) || isempty(templateValues)
    return;
end

for k = 1:2
    requests(k).ok = true;
    requests(k).timeOffset = t;
    requests(k).segments = X;
    requests(k).template = templateValues;
end
residStd = std(X - templateValues, 0, 2, 'omitnan');
requests(1).upper = templateValues + residStd;
requests(1).lower = templateValues - residStd;
requests(1) = addMeasurementWindows(requests(1), measurements);
maxShow = min(40, size(X, 2));
requests(2).showIndex = unique(round(linspace(1, size(X, 2), maxShow)));
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
