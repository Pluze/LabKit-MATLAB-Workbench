function view = present(cache, projectResults, sourceCount, viewRevision)
%PRESENT Build the Focus Stack result summary and quality previews model.
result = cache.result;
view = labkit.app.view.Snapshot();
view = view.enabled("exportFused", result.ok);
view = view.enabled("exportFocusMap", result.ok);
view = view.enabled("exportSummary", result.ok);
if result.ok
    data = focus_stack.focusPreview.resultTableData(result);
    details = focus_stack.focusPreview.details( ...
        result, cache.sourcePaths, ...
        cellstr(projectResults.registrationLines));
    details{end + 1} = ...
        "Confidence compares the two strongest detail scores; it is not a probability or a physical depth measurement.";
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
    "images", {cache.images}, "result", result), ...
    ViewRevision=viewRevision);
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
