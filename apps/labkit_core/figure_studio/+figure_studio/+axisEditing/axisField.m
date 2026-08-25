%AXISFIELD Map a control-panel axis name to the document field.
function name = axisField(target)
switch upper(strtrim(string(target)))
    case "X"
        name = "x";
    case "Y"
        name = "y";
    case "RIGHT Y"
        name = "yRight";
    case "Z"
        name = "z";
    otherwise
        error("figure_studio:axisEditing:UnknownAxis", ...
            "Unknown axis target: %s", string(target));
end
end
