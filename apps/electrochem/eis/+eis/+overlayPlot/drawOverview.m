function drawOverview(axesById, model)
%DRAWOVERVIEW Show source curves or explicitly grouped mean/SD coordinates.
% Called by the EIS workspace with decoded items and display options. No
% interpolation, equivalent-circuit fitting, or numerical export is performed.
model.items = compactOverviewNames(model.items);
axesIds = ["nyquist" "magnitude" "phase"];
xNames = ["Zreal" "Freq (Hz)" "Freq (Hz)"];
yNames = ["-Zimag" "Zmod" "Zphz (deg)"];
titles = ["Nyquist" "Impedance magnitude" "Phase"];
if model.hasItems && isfield(model.options, "frequencyLogRange")
    bounds = 10.^model.options.frequencyLogRange;
    titles(1) = "Nyquist (" + eis.overlayPlot.formatFrequency(bounds(1)) + " – " + ...
        eis.overlayPlot.formatFrequency(bounds(2)) + ")";
end
for k = 1:numel(axesIds)
    if ~isfield(axesById, axesIds(k)), continue; end
    ax = axesById.(axesIds(k));
    options = model.options;
    options.xName = xNames(k);
    options.yName = yNames(k);
    options.logX = k > 1;
    options.logY = false;
    options.showLegend = options.showLegend && k == 1;
    panel = model;
    panel.options = options;
    panel.viewAction = "";
    eis.overlayPlot.draw(struct("main", ax), panel);
    title(ax, titles(k));
end
if model.hasItems && isfield(axesById, "nyquist")
    if model.options.showLegend
        columns = 1;
        key = legend(axesById.nyquist, Location="eastoutside", ...
            NumColumns=columns, Box="off");
        key.String = wrapLegendLabels(string(key.String));
    end
    ax = axesById.nyquist;
    eis.overlayPlot.fitNyquistViewport(ax);
end
if model.hasItems && isfield(model.options, "frequencyLogRange")
    for axisId = ["magnitude" "phase"]
        if ~isfield(axesById, axisId), continue; end
        ax = axesById.(axisId);
        range = model.options.frequencyLogRange;
        if range(1) == range(2)
            % Give a single selected frequency a usable logarithmic axis.
            range = range + [-.05 .05];
        end
        xlim(ax, 10.^range);
    end
end
end

function items = compactOverviewNames(items)
% Remove only shared filename-prefix segments; distinct suffixes stay intact.
% The Files list, custom plot, group names, and exports retain full names.
if numel(items) < 2 || isfield(items, "members"), return; end
names = string({items.name});
first = char(names(1));
cut = 0;
for k = 1:numel(first)
    if ~all(startsWith(names, string(first(1:k)))), break; end
    if any(first(k) == ['-' '_' ' ']), cut = k; end
end
if cut == 0 || any(strlength(names) <= cut), return; end
for k = 1:numel(items)
    items(k).name = extractAfter(names(k), cut);
end
end

function labels = wrapLegendLabels(labels)
% Bound a side legend's width without shortening the displayed source names.
maximumLineLength = 22;
for k = 1:numel(labels)
    remaining = char(labels(k));
    lines = strings(numel(remaining)+1, 1);
    lineCount = 0;
    while numel(remaining) > maximumLineLength
        cut = find(ismember(remaining(1:maximumLineLength), '-_ '), 1, 'last');
        if isempty(cut), cut = maximumLineLength; end
        lineCount = lineCount + 1;
        lines(lineCount) = string(remaining(1:cut));
        remaining = remaining(cut+1:end);
    end
    labels(k) = join([lines(1:lineCount); string(remaining)], newline);
end
end
