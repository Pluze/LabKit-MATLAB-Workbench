function view = present(state)
%PRESENT Build the Focus Stack result summary and paired preview model.
cacheResult = state.session.cache.result;
result = visibleResult(state, cacheResult);
view = labkit.app.view.Snapshot();
view = view.enabled("exportFused", cacheResult.ok);
view = view.enabled("exportFocusMap", cacheResult.ok);
view = view.enabled("exportSummary", cacheResult.ok);
if result.ok
    data = focus_stack.focusPreview.resultTableData(result);
    details = focus_stack.focusPreview.details( ...
        result, state.session.cache.sourcePaths, ...
        cellstr(state.project.results.registrationLines));
    if ~cacheResult.ok
        details{end + 1} = ...
            "Saved summary restored; rerun to rebuild image previews and exports.";
    end
    if strlength(state.project.results.resultManifestPath) > 0
        details{end + 1} = ...
            "Last manifest: " + state.project.results.resultManifestPath;
    end
else
    data = focus_stack.focusPreview.initialResultTable();
    details = pendingDetails(numel(state.session.cache.images), ...
        numel(state.project.inputs.sources));
end
view = view.tableData("resultTable", data, Columns=["Metric" "Value"]);
view = view.text("details", strjoin(string(details), newline));
view = view.renderPlot("preview", struct( ...
    "images", {state.session.cache.images}, "result", cacheResult));
end

function result = visibleResult(state, cacheResult)
result = cacheResult;
if result.ok
    return;
end
durable = state.project.results.lastRun;
if durable.ok && strlength(state.session.cache.currentFingerprint) > 0 && ...
        state.session.cache.currentFingerprint == ...
        state.project.results.lastRunFingerprint
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
