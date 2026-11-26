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
    options.overviewTitle = titles(k);
    panel = model;
    panel.options = options;
    panel.viewAction = "";
    eis.overlayPlot.draw(struct("main", ax), panel);
    if ~model.hasItems, title(ax, titles(k)); end
end
if model.hasItems && isfield(axesById, "nyquist")
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
