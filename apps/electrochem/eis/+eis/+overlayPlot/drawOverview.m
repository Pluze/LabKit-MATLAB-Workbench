function drawOverview(axesById, model)
%DRAWOVERVIEW Show source curves or explicitly grouped mean/SD coordinates.
% Called by the EIS workspace with decoded items and display options. No
% interpolation, equivalent-circuit fitting, or numerical export is performed.
model.items = compactOverviewNames(model.items);
axesIds = ["nyquist" "magnitude" "phase"];
xNames = ["Zreal" "Freq (Hz)" "Freq (Hz)"];
yNames = ["-Zimag" "Zmod" "Zphz (deg)"];
titles = ["" "Impedance magnitude" "Phase"];
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
    % Nyquist's panel owns its title so equal data units cannot clip it.
    title(ax, titles(k));
end
if model.hasItems && isfield(axesById, "nyquist")
    if model.options.showLegend
        names = string({model.items.name});
        columns = 1;
        if all(strlength(names) <= 18), columns = min(3, numel(names)); end
        legend(axesById.nyquist, Location="southoutside", ...
            NumColumns=columns, Box="off");
    end
    labkit.app.plot.fitAxesToGraphics(axesById.nyquist, EqualDataUnits=true);
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
