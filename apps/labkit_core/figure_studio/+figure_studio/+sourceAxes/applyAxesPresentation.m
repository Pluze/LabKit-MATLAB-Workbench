%APPLYAXESPRESENTATION Apply stored editable axes metadata to one axes.
% Expected callers are the Figure Studio preview and export renderers. Inputs
% are a live destination axes and the plain axes metadata snapshot.
function applyAxesPresentation(ax, metadata)
arguments
    ax
    metadata (1, 1) struct
end
if isempty(ax) || ~isvalid(ax)
    error("figure_studio:sourceAxes:InvalidAxes", ...
        "The destination axes is not valid.");
end
if isfield(metadata, "title")
    label = title(ax, string(metadata.title));
    applyInterpreter(label, metadata, "titleInterpreter");
end
if isfield(metadata, "xLabel")
    label = xlabel(ax, string(metadata.xLabel));
    applyInterpreter(label, metadata, "xLabelInterpreter");
end
if isfield(metadata, "yLabel")
    label = ylabel(ax, string(metadata.yLabel));
    applyInterpreter(label, metadata, "yLabelInterpreter");
end
mapping = { ...
    "XLim", "xLim"; "YLim", "yLim"; "ZLim", "zLim"; ...
    "XScale", "xScale"; "YScale", "yScale"; "ZScale", "zScale"; ...
    "XDir", "xDir"; "YDir", "yDir"; "ZDir", "zDir"; ...
    "XAxisLocation", "xAxisLocation"; ...
    "YAxisLocation", "yAxisLocation"; ...
    "XMinorTick", "xMinorTick"; "YMinorTick", "yMinorTick"; ...
    "ZMinorTick", "zMinorTick"; ...
    "XTick", "xTick"; "YTick", "yTick"; "ZTick", "zTick"; ...
    "XTickLabel", "xTickLabel"; ...
    "YTickLabel", "yTickLabel"; ...
    "ZTickLabel", "zTickLabel"; ...
    "XTickLabelRotation", "xTickLabelRotation"; ...
    "YTickLabelRotation", "yTickLabelRotation"; ...
    "ZTickLabelRotation", "zTickLabelRotation"};
for index = 1:size(mapping, 1)
    property = char(mapping{index, 1});
    field = char(mapping{index, 2});
    if ~isfield(metadata, field) || isempty(metadata.(field))
        continue;
    end
    try
        ax.(property) = metadata.(field);
    catch
    end
end
end

function applyInterpreter(label, metadata, field)
name = char(field);
if ~isfield(metadata, name)
    return;
end
value = string(metadata.(name));
if isscalar(value) && any(value == ["tex", "latex", "none"])
    label.Interpreter = char(value);
end
end
