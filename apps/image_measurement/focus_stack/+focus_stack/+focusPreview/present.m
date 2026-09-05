% App-owned implementation for focus_stack.focusPreview.present within the focus_stack product workflow.
function view = present(cache, projectResults, sourceCount, viewRevision)
%PRESENT Build the Focus Stack result summary and quality previews model.
cacheResult = cache.result;
result = visibleResult(cache, projectResults, cacheResult);
view = labkit.app.view.Snapshot();
view = view.enabled("exportFused", cacheResult.ok);
view = view.enabled("exportFocusMap", cacheResult.ok);
view = view.enabled("exportSummary", cacheResult.ok);
if result.ok
    data = focus_stack.focusPreview.resultTableData(result);
    details = focus_stack.focusPreview.details( ...
        result, cache.sourcePaths, ...
        cellstr(projectResults.registrationLines));
    details{end + 1} = ...
        "Confidence compares the two strongest detail scores; it is not a probability or a physical depth measurement.";
    if ~cacheResult.ok
        details{end + 1} = ...
            "Saved summary restored; rerun to rebuild image previews and exports.";
    end
    if strlength(projectResults.lastOutputPath) > 0
        details{end + 1} = ...
            "Last output: " + projectResults.lastOutputPath;
    end
else
    data = focus_stack.focusPreview.initialResultTable();
    details = pendingDetails(numel(cache.images), sourceCount);
end
view = view.tableData("resultTable", data, Columns=["Metric" "Value"]);
view = view.text("details", strjoin(string(details), newline));
view = view.renderPlot("preview", struct( ...
    "images", {cache.images}, "result", cacheResult), ...
    ViewRevision=viewRevision);
end

function result = visibleResult(cache, projectResults, cacheResult)
result = cacheResult;
if result.ok
    return;
end
durable = projectResults.lastRun;
if durable.ok && strlength(cache.currentFingerprint) > 0 && ...
        cache.currentFingerprint == projectResults.lastRunFingerprint
    result = durable;
end
end

function lines = pendingDetails(imageCount, sourceCount)
if imageCount >= 2
    lines = {sprintf("Loaded images: %d", sourceCount), ...
        "Run focus stack to compute the fused image and focus-depth map."};
elseif sourceCount > 0
    lines = {sprintf("Loaded images: %d", sourceCount), ...
        "Load at least two images before running focus stack."};
else
    lines = { ...
        "Load a focus image folder or select image files to begin."};
end
end
