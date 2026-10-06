function area_mm2 = crossSectionArea(parameters)
%CROSSSECTIONAREA Resolve the initial loaded cross section in square mm.
% Only the selected mode's dimensions affect area. The initial axial
% length/height is independent of the two rectangular cross-section sides.
mode = string(parameters.crossSectionMode);
if ~isscalar(mode)
    error("mark10_monitor:analysis:InvalidGeometry", ...
        "Select one cross-section mode.");
end
switch mode
    case "Length x width"
        area_mm2 = positive(parameters.width_mm, "Cross-section length") * ...
            positive(parameters.thickness_mm, "Cross-section width");
    case "Radius"
        radius = positive(parameters.radius_mm, "Radius");
        area_mm2 = pi * radius^2;
    case "Area"
        area_mm2 = positive(parameters.area_mm2, "Area");
    otherwise
        error("mark10_monitor:analysis:InvalidGeometry", ...
            "Select Length x width, Radius, or Area.");
end
positive(area_mm2, "Calculated area");
end

function value = positive(value, name)
value = double(value);
if ~isscalar(value) || ~isreal(value) || ~isfinite(value) || value <= 0
    error("mark10_monitor:analysis:InvalidGeometry", ...
        "%s must be finite and positive (mm for lengths, mm^2 for area).", name);
end
end
