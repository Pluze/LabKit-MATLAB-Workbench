%CLASSIFYROLE Infer a presentation role without changing scientific meaning.
% Expected caller: Figure Studio document import. The result is an editable
% presentation category. App-owned source data and calculations are untouched.
function role = classifyRole(object)
kind = lower(string(fieldValue(object, "type", "unknown")));
name = lower(string(fieldValue(object, "displayName", "")));
meta = fieldValue(object, "metadata", struct());
handleVisibility = lower(string(fieldValue(meta, "handleVisibility", "on")));
style = fieldValue(object, "style", struct());

switch kind
    case "errorbar"
        role = "uncertainty";
    case {"bar", "boxchart"}
        role = "summary";
    case "constantline"
        role = "reference-line";
    case "rectangle"
        role = "region";
    case "text"
        role = textRole(name);
    case "image"
        role = "image";
    case "surface"
        role = "scalar-field";
    case {"area", "patch"}
        role = fillRole(style, name);
    case {"line", "scatter"}
        role = lineRole(style, name, handleVisibility);
    otherwise
        role = "unclassified";
end
end

function role = lineRole(style, name, handleVisibility)
if containsAny(name, ["fit", "model", "regression"])
    role = "fit";
elseif containsAny(name, ["mean", "median", "template", "summary"])
    role = "summary";
elseif containsAny(name, ["threshold", "baseline", "reference", "start", "end"])
    role = "reference-line";
elseif handleVisibility == "off" || isDashed(style)
    role = "annotation-line";
elseif containsAny(name, ["point", "peak", "marker", "hot", "cold"])
    role = "measurement-point";
else
    role = "raw-data";
end
end

function role = fillRole(style, name)
alpha = fieldValue(style, "FaceAlpha", 1);
if containsAny(name, ["error", "uncertainty", "confidence", "deviation"]) || ...
        (isnumeric(alpha) && isscalar(alpha) && alpha < 0.5)
    role = "uncertainty-band";
elseif containsAny(name, ["window", "region", "interval"])
    role = "analysis-window";
else
    role = "filled-region";
end
end

function role = textRole(name)
if containsAny(name, ["scale", "µm", "mm", "cm"])
    role = "scale-label";
elseif containsAny(name, ["*", "ns", "p =", "p="])
    role = "significance-label";
else
    role = "annotation-text";
end
end

function tf = isDashed(style)
lineStyle = string(fieldValue(style, "LineStyle", "-"));
tf = any(lineStyle == ["--", ":", "-."]);
end

function tf = containsAny(value, candidates)
tf = any(contains(value, candidates, IgnoreCase=true));
end

function value = fieldValue(owner, name, fallback)
name = char(name);
if isstruct(owner) && isfield(owner, name)
    value = owner.(name);
else
    value = fallback;
end
end
