function output = buildBatchTable(sources, annotations, templates, results)
%BUILDBATCHTABLE Build current ROI/channel rows plus explicit missing-source rows.
% Called by explicit batch export. Uses saved measurements only, never IO
% or recalculation. ImageIndex distinguishes equal filenames in a batch.
parts = cell(numel(sources), 1);
for k = 1:numel(sources)
    source = sources(k);
    annotation = roi_analyzer.roiLibrary.annotationForSource(annotations, source.id);
    result = roi_analyzer.analysisRun.resultForSource(results.items, source.id);
    summary = result.summary;
    if isempty(summary)
        row = roi_analyzer.analysisRun.emptyRow();
        row.PixelCount = NaN;
        row.Ratio = NaN;
        summary = struct2table(row);
        status = roi_analyzer.resultFiles.measurementStatus(source.id, annotation.rois, results);
        adjusted = NaN;
    else
        status = repmat("Measured", height(summary), 1);
        status(summary.PixelCount == 0) = "No finite pixels";
        adjusted = geometryAdjusted(summary, annotation.rois, templates);
    end
    [~, name, extension] = fileparts(string(source.path));
    rows = roi_analyzer.resultFiles.buildExportTable(summary, string(name) + string(extension));
    rows.ImageIndex = repmat(k, height(rows), 1);
    rows.Status = status;
    rows.GeometryAdjusted = adjusted;
    rows = movevars(rows, ["ImageIndex" "Status" "GeometryAdjusted"], "Before", "Image");
    parts{k} = rows;
end
output = table();
if ~isempty(parts)
    output = vertcat(parts{:});
end
end

function adjusted = geometryAdjusted(summary, definitions, templates)
adjusted = NaN(height(summary), 1);
for row = 1:height(summary)
    index = find(string({definitions.id}) == summary.RoiId(row), 1);
    if isempty(index), continue; end
    definition = definitions(index);
    index = find(string({templates.id}) == string(definition.templateId), 1);
    if isempty(index), continue; end
    geometry = double(templates(index).size);
    expected = [double(definition.centerXY) - (geometry - 1) ./ 2, geometry];
    actual = [summary.X(row), summary.Y(row), summary.Width(row), summary.Height(row)];
    adjusted(row) = double(any(actual ~= expected));
end
end
