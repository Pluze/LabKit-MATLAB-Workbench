function [items, status, failures] = measureSources(sources, annotations, templates, referenceId, progressFcn)
%MEASURESOURCES Measure one immutable source/ROI snapshot, reading one image at a time.
% Called by Run All. Replaces each source result, including failed/empty items,
% and returns exceptions to the callback for reporting without retaining them.
if nargin < 5, progressFcn = []; end
lastProgress = tic;
report(progressFcn, "started", 0, numel(sources));
item = roi_analyzer.analysisRun.resultForSource( ...
    repmat(struct("sourceId", "", "roiFingerprint", "", ...
    "summary", table(), "metrics", table()), 0, 1), "");
items = repmat(item, numel(sources), 1);
labels = strings(numel(sources), 1);
ids = strings(numel(sources), 1);
failures = cell(numel(sources), 1);
for k = 1:numel(sources)
    if toc(lastProgress) >= 5
        report(progressFcn, "measuring", k - 1, numel(sources));
        lastProgress = tic;
    end
    items(k).sourceId = string(sources(k).id);
    ids(k) = items(k).sourceId;
    annotation = roi_analyzer.roiLibrary.annotationForSource( ...
        annotations, sources(k).id);
    if isempty(annotation.rois)
        labels(k) = "No ROIs";
        continue
    end
    try
        records = labkit.image.readFiles( ...
            labkit.app.source.paths(sources(k)), struct("Normalize", false));
        pixels = records(1).image;
    catch cause
        labels(k) = "Read failed";
        failures{k} = cause;
        continue
    end
    try
        resolved = roi_analyzer.roiTemplates.resolve( ...
            annotation.rois, templates, size(pixels));
        measured = roi_analyzer.analysisRun.measureImage(pixels, resolved, referenceId);
        items(k).roiFingerprint = measured.roiFingerprint;
        items(k).summary = measured.summary;
        items(k).metrics = measured.summary;
        labels(k) = "Measured";
    catch cause
        labels(k) = "Measurement failed";
        failures{k} = cause;
    end
end
report(progressFcn, "completed", numel(sources), numel(sources));
status = table(ids, labels, ...
    VariableNames=["SourceId" "Status"]);
end

function report(progressFcn, stage, completed, total)
if ~isempty(progressFcn), progressFcn(stage, completed, total); end
end
