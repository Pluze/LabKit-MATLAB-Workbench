function sample = decodeSample(raw)
%DECODESAMPLE Decode one ESM303 combined force/travel response.
%
% Usage:
%   sample = labkit.mark10.decodeSample(raw)
%
% Description:
%   Locates a force line immediately followed by a travel line in an ESM303
%   n response, converts force to newtons and travel to millimeters, and
%   retains the raw values and units. Extra force-only lines before the pair
%   are ignored as possible unsolicited Series 5 contamination. Unknown
%   units and malformed pairs return Valid=false rather than plausible data.
%
% Inputs:
%   raw - Character, scalar string, or uint8 response bytes.
%
% Outputs:
%   sample - Scalar struct with Force_N, Travel_mm, raw value/unit fields,
%       Valid, AcquisitionMode, and RawText.
%
% Errors:
%   labkit:mark10:InvalidValue - raw has an unsupported type.
%
% Example:
%   sample = labkit.mark10.decodeSample("1.000 N" + newline + ...
%       "2.00 mm" + newline);
%   assert(sample.Valid && sample.Force_N == 1 && sample.Travel_mm == 2)
%
% See also labkit.mark10.readSample, labkit.mark10.decodeSettings
    text = responseText(raw);
    lines = split(replace(text, char(13), ""), newline);
    forceValue = NaN;
    forceUnit = "";
    travelValue = NaN;
    travelUnit = "";
    for index = 2:numel(lines)
        [candidateTravel, candidateTravelUnit] = parseTravel(lines(index));
        [candidateForce, candidateForceUnit] = parseForce(lines(index - 1));
        if isfinite(candidateTravel) && isfinite(candidateForce)
            travelValue = candidateTravel;
            travelUnit = candidateTravelUnit;
            forceValue = candidateForce;
            forceUnit = candidateForceUnit;
            break;
        end
    end
    forceN = forceToN(forceValue, forceUnit);
    travelMm = travelToMm(travelValue, travelUnit);
    sample = struct( ...
        "Force_N", forceN, "Travel_mm", travelMm, ...
        "ForceRawValue", forceValue, "ForceUnit", forceUnit, ...
        "TravelRawValue", travelValue, "TravelUnit", travelUnit, ...
        "Valid", isfinite(forceN) && isfinite(travelMm), ...
        "AcquisitionMode", "Synchronized n", "RawText", text, ...
        "FailureStatus", "");
end

function text = responseText(raw)
if ischar(raw)
    text = string(raw);
elseif isstring(raw) && isscalar(raw)
    text = raw;
elseif isa(raw, "uint8") || (isnumeric(raw) && all(isfinite(raw), "all"))
    text = string(native2unicode(uint8(raw(:).'), "UTF-8"));
else
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 response must be text or byte values.");
end
end

function [value, unit] = parseForce(text)
token = regexp(char(strip(text)), ...
    '^([-+]?\d+(?:\.\d+)?)\s*([A-Za-z]+)$', 'tokens', 'once');
[value, unit] = tokenValue(token);
end

function [value, unit] = parseTravel(text)
token = regexp(char(strip(text)), ...
    '^([-+]?\d+(?:\.\d+)?)\s*(mm|in)$', ...
    'tokens', 'once', 'ignorecase');
[value, unit] = tokenValue(token);
end

function [value, unit] = tokenValue(token)
if isempty(token)
    value = NaN;
    unit = "";
else
    value = str2double(token{1});
    unit = string(token{2});
end
end

function value = forceToN(value, unit)
if ~isfinite(value)
    value = NaN;
    return;
end
switch lower(unit)
    case "n"
    case "mn"
        value = value / 1000;
    case "kn"
        value = value * 1000;
    case "lbf"
        value = value * 4.4482216152605;
    case "ozf"
        value = value * 0.278013850953781;
    case "kgf"
        value = value * 9.80665;
    case "gf"
        value = value * 0.00980665;
    otherwise
        value = NaN;
end
end

function value = travelToMm(value, unit)
if lower(unit) == "in"
    value = value * 25.4;
elseif lower(unit) ~= "mm"
    value = NaN;
end
end
