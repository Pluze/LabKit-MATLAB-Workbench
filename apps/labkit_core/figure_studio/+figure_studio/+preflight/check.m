%CHECK Audit a Figure Studio document before publication export.
function report = check(document, style)
issues = repmat(issue("", "", "", "", "", ""), ...
    3 + numel(document.warnings), 1);
count = 0;
if isempty(document.panels)
    count = count + 1;
    issues(count) = issue("error", "empty-document", "", "", ...
        "The document has no panels.", "Import or create a panel.");
end
if document.canvas.width < 300 || document.canvas.height < 250
    count = count + 1;
    issues(count) = issue("warning", "small-canvas", "", "", ...
        "The output canvas is unusually small.", ...
        "Increase canvas width or height.");
end
padding = document.canvas.padding;
if padding(1) + padding(2) >= document.canvas.width || ...
        padding(3) + padding(4) >= document.canvas.height
    count = count + 1;
    issues(count) = issue("error", "invalid-padding", "", "", ...
        "Canvas padding consumes the available drawing area.", ...
        "Reduce one or more padding values.");
end
issues = issues(1:count);
panelValues = panelIssues(document);
nodeValues = nodeIssues(document);
styleValues = styleIssues(style);
warningValues = repmat(issue("", "", "", "", "", ""), ...
    numel(document.warnings), 1);
for k = 1:numel(document.warnings)
    warningValues(k) = issue("warning", "import-warning", "", "", ...
        document.warnings(k), ...
        "Keep native pass-through or replace the unsupported object.");
end
issues = [issues(:); panelValues(:); nodeValues(:); styleValues(:); ...
    warningValues(:)];
severities = string({issues.severity});
report = struct("status", statusValue(severities), ...
    "errors", sum(severities == "error"), ...
    "warnings", sum(severities == "warning"), ...
    "issues", issues);
end

function issues = panelIssues(document)
panelCount = numel(document.panels);
issues = repmat(issue("", "", "", "", "", ""), ...
    5 * panelCount + panelCount * max(panelCount - 1, 0) / 2, 1);
count = 0;
for k = 1:numel(document.panels)
    panel = document.panels(k);
    geometry = panel.geometry;
    if any(~isfinite(geometry)) || any(geometry(3:4) <= 0) || ...
            any(geometry(1:2) < 0) || any(geometry(1:2) + geometry(3:4) > 1)
        count = count + 1;
        issues(count) = issue("error", "panel-outside-canvas", ...
            panel.id, "", "Panel geometry lies outside the canvas.", ...
            "Move or resize the panel inside the 0–1 bounds.");
    end
    nodes = document.nodes(string({document.nodes.panelId}) == panel.id & ...
        string({document.nodes.kind}) ~= "group");
    for axisName = ["x", "y"]
        axisValue = panel.axes.(char(axisName));
        if axisValue.scale == "log" && hasNonpositive(nodes, axisName)
            count = count + 1;
            issues(count) = issue("error", "nonpositive-log-data", ...
                panel.id, "", "A logarithmic axis contains nonpositive data.", ...
                "Use linear scale or exclude invalid values in the source App.");
        end
    end
    if strlength(panel.text.xLabel) == 0 && varies(nodes, "x")
        count = count + 1;
        issues(count) = issue("warning", "missing-x-label", panel.id, "", ...
            "The X axis has varying data but no label.", "Add an X-axis label.");
    end
    if strlength(panel.text.yLabel) == 0 && varies(nodes, "y")
        count = count + 1;
        issues(count) = issue("warning", "missing-y-label", panel.id, "", ...
            "The Y axis has varying data but no label.", "Add a Y-axis label.");
    end
end
for left = 1:numel(document.panels)
    for right = left + 1:numel(document.panels)
        if overlapArea(document.panels(left).geometry, ...
                document.panels(right).geometry) > 1e-6
            count = count + 1;
            issues(count) = issue("warning", "panel-overlap", ...
                document.panels(left).id, document.panels(right).id, ...
                "Two panels overlap.", "Align, distribute, or resize the panels.");
        end
    end
end
issues = issues(1:count);
end

function issues = nodeIssues(document)
issues = repmat(issue("", "", "", "", "", ""), ...
    2 * numel(document.nodes), 1);
count = 0;
for k = 1:numel(document.nodes)
    node = document.nodes(k);
    if isfield(node.metadata, "yAxisSideConfidence") && ...
            string(node.metadata.yAxisSideConfidence) == "fallback"
        count = count + 1;
        issues(count) = issue("warning", "ambiguous-y-axis", ...
            node.panelId, node.id, ...
            "The object's left/right Y-axis assignment was inferred ambiguously.", ...
            "Verify its Axis value in the Objects table.");
    end
    if ~node.visible || node.kind == "group", continue; end
    panelIndex = find(string({document.panels.id}) == node.panelId, 1);
    if isempty(panelIndex), continue; end
    panel = document.panels(panelIndex);
    if outside(node.data.x, panel.axes.x.limits) || ...
            outside(node.data.y, panel.axes.y.limits)
        count = count + 1;
        issues(count) = issue("warning", "object-outside-limits", ...
            node.panelId, node.id, ...
            "A visible object extends outside the displayed axis limits.", ...
            "Expand limits or intentionally hide/clip the object.");
    end
end
issues = issues(1:count);
end

function issues = styleIssues(style)
issues = repmat(issue("", "", "", "", "", ""), 6, 1);
count = 0;
for name = ["tickFontSize", "labelFontSize", "annotationFontSize"]
    if isfield(style, name) && double(style.(char(name))) < 7
        count = count + 1;
        issues(count) = issue("warning", "small-text", "", "", ...
            name + " is below 7 pt at reference size.", ...
            "Increase the corresponding text size.");
    end
end
for name = ["dataLineWidth", "axesLineWidth", "referenceLineWidth"]
    if isfield(style, name) && double(style.(char(name))) < 0.5
        count = count + 1;
        issues(count) = issue("warning", "thin-stroke", "", "", ...
            name + " is below 0.5 pt at reference size.", ...
            "Increase the corresponding stroke width.");
    end
end
issues = issues(1:count);
end

function tf = hasNonpositive(nodes, axisName)
tf = false;
for node = reshape(nodes, 1, [])
    values = node.data.(char(axisName));
    if any(isfinite(values(:)) & values(:) <= 0), tf = true; return; end
end
end

function tf = varies(nodes, axisName)
chunks = cell(numel(nodes), 1);
for k = 1:numel(nodes)
    values = nodes(k).data.(char(axisName));
    if isnumeric(values), chunks{k} = values(:); else, chunks{k} = []; end
end
allValues = vertcat(chunks{:});
allValues = allValues(isfinite(allValues));
tf = numel(unique(allValues)) > 1;
end

function tf = outside(values, limits)
tf = false;
if ~isnumeric(values) || isempty(values), return; end
values = values(isfinite(values));
tf = any(values < limits(1) | values > limits(2));
end

function value = overlapArea(a, b)
width = max(0, min(a(1)+a(3), b(1)+b(3)) - max(a(1), b(1)));
height = max(0, min(a(2)+a(4), b(2)+b(4)) - max(a(2), b(2)));
value = width * height;
end

function value = statusValue(severities)
if any(severities == "error"), value = "blocked";
elseif any(severities == "warning"), value = "review";
else, value = "ready";
end
end

function value = issue(severity, code, panelId, nodeId, message, fix)
value = struct("severity", string(severity), "code", string(code), ...
    "panelId", string(panelId), "nodeId", string(nodeId), ...
    "message", string(message), "suggestedFix", string(fix));
end
