% App-owned implementation for ecg_print.analysisRun.previewModels within the ecg_print product workflow.
function models = previewModels(cache, parameters)
emptyRequest = struct();
models = repmat(struct( ...
    "axisId", "", "kind", "", "request", emptyRequest, ...
    "analysis", table(), "smoothBeats", parameters.smoothBeats, ...
    "unit", "", "showXLabel", true), 1, 6);
unit = ecg_print.analysisRun.signalUnit(cache.workingSignal);
models(1).axisId = "wave";
models(1).kind = "wave";
models(1).request = ecg_print.analysisRun.waveformPlotRequest( ...
    cache.workingSignal, cache.filteredSignal, cache.events, ...
    cache.filepath);
models(1).request = displayWaveform(models(1).request);
models(1).showXLabel = false;
analysis = table();
if ~isempty(cache.measurements) && ~isempty(cache.measurements.perSegment)
    analysis = ecg_print.resultFiles.analysisTable(cache.measurements.perSegment, parameters.smoothBeats);
end
models(2).axisId = "noise";
models(2).kind = "noise";
models(2).analysis = analysis;
models(2).unit = unit;
models(2).showXLabel = false;
models(3).axisId = "peak";
models(3).kind = "peak";
models(3).analysis = analysis;
models(3).unit = unit;
models(3).showXLabel = false;
models(4).axisId = "snr";
models(4).kind = "snr";
models(4).analysis = analysis;
templateRequests = ecg_print.analysisRun.templatePlotRequests( ...
    cache.segments, cache.template, cache.measurements, unit);
templateRequests = displayTemplates(templateRequests);
models(5).axisId = "templateResidual";
models(5).kind = "template";
models(5).request = templateRequests(1);
models(6).axisId = "templateSegments";
models(6).kind = "template";
models(6).request = templateRequests(2);
end

function request = displayWaveform(request)
maximumPoints = 6000;
if ~request.ok || numel(request.x) <= maximumPoints
    return;
end
binCount = floor(maximumPoints / 2);
edges = round(linspace(1, numel(request.x) + 1, binCount + 1));
index = zeros(2 * binCount, 1);
count = 0;
for k = 1:binCount
    range = edges(k):max(edges(k), edges(k + 1) - 1);
    values = request.y(range);
    finite = find(isfinite(values));
    if isempty(finite)
        selected = [1 numel(range)];
    else
        [~, low] = min(values(finite));
        [~, high] = max(values(finite));
        selected = finite([low high]);
    end
    selected = unique(selected);
    index(count + (1:numel(selected))) = range(selected);
    count = count + numel(selected);
end
index = unique([1; sort(index(1:count)); numel(request.x)]);
request.x = request.x(index);
request.y = request.y(index);
end

function requests = displayTemplates(requests)
maximumRows = 1601;
if ~requests(1).ok || numel(requests(1).timeOffset) <= maximumRows
    return;
end
rowCount = numel(requests(1).timeOffset);
index = unique([round(linspace(1, rowCount, maximumRows)).'; ...
    find(abs(requests(1).timeOffset) == ...
    min(abs(requests(1).timeOffset)), 1)]);
for k = 1:numel(requests)
    requests(k).timeOffset = requests(k).timeOffset(index);
    requests(k).segments = requests(k).segments(index, :);
    requests(k).template = requests(k).template(index);
    if ~isempty(requests(k).upper)
        requests(k).upper = requests(k).upper(index);
        requests(k).lower = requests(k).lower(index);
    end
end
end
