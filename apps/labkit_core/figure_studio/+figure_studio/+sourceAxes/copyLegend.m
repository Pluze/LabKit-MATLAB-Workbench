%COPYLEGEND Recreate a visible source legend for copied Figure Studio axes.
% Expected callers: native preview and export copies. Inputs are the source
% axes and its copied destination axes; source graphics are never modified.
function copyLegend(srcAx, dstAx)
if ~isprop(srcAx, "Legend") || isempty(srcAx.Legend) || ...
        ~isvalid(srcAx.Legend)
    return;
end
srcLegend = srcAx.Legend;
if string(srcLegend.Visible) == "off"
    return;
end
try
    dstLegend = legend(dstAx, "show", "Interpreter", "none");
catch
    return;
end
properties = {"String", "Location", "Orientation", "NumColumns", ...
    "FontName", "FontSize", "Box", "Interpreter", "Visible"};
for k = 1:numel(properties)
    property = properties{k};
    try
        if isprop(srcLegend, property) && isprop(dstLegend, property)
            dstLegend.(property) = srcLegend.(property);
        end
    catch
    end
end
end
