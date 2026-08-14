function state = copyReadback(state, value)
%COPYREADBACK Normalize driver settings into visible and editable App state.
if strlength(value.Raw) == 0
    return;
end
state.session.settings = struct( ...
    "unit", value.Unit, "mode", value.Mode, ...
    "currentFilter", value.CurrentFilter, ...
    "displayFilter", value.DisplayFilter, ...
    "outputFormat", value.OutputFormat, ...
    "autoOutput", value.AutoOutput, ...
    "autoShutoff", value.AutoShutoff, ...
    "invertPolarity", value.InvertPolarity, ...
    "omitPolarity", value.OmitPolarity, "raw", value.Raw);
draft = state.session.settingsDraft;
draft.unit = displayUnit(value.Unit);
draft.mode = value.Mode;
draft.currentFilter = string(value.CurrentFilter);
draft.displayFilter = string(value.DisplayFilter);
draft.outputFormat = value.OutputFormat;
draft.autoOutput = string(value.AutoOutput);
state.session.settingsDraft = draft;
end

function value = displayUnit(value)
switch upper(value)
    case "MN", value = "mN";
    case "KN", value = "kN";
    case "LBF", value = "lbF";
    case "OZF", value = "ozF";
    case "KGF", value = "kgF";
    case "GF", value = "gF";
end
end
