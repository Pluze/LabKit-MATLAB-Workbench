function settings = decodeSettings(raw)
%DECODESETTINGS Decode a Series 5 LIST response.
%
% Usage:
%   settings = labkit.mark10.decodeSettings(raw)
%
% Description:
%   Extracts a semicolon-delimited LIST record, including when force-only
%   Auto Output lines surround it. Known fields are normalized and the raw
%   record is retained so later firmware fields remain protocol-transparent.
%
% Inputs:
%   raw - Character, scalar string, or byte response.
%
% Outputs:
%   settings - Scalar struct with Version, Unit, Mode, CurrentFilter,
%       DisplayFilter, AutoOutput, ActiveAutoOutput, AutoShutoff,
%       OutputFormat, InvertPolarity, OmitPolarity, Battery, UnknownTokens,
%       and Raw fields. Filters are sample counts, not GCL2 exponents.
%
% Errors:
%   labkit:mark10:InvalidValue - raw has an unsupported type.
%
% Example:
%   settings = labkit.mark10.decodeSettings( ...
%       "V1.00;N;CUR;FLTC3;FLTP1;AOUT0;AOFF5;FULL;IPOL0;OPOL0;B0");
%   assert(settings.CurrentFilter == 8)
%
% See also labkit.mark10.readSettings, labkit.mark10.writeSetting
    text = responseText(raw);
    record = extractRecord(text);
    settings = struct( ...
        "Version", "", "Unit", "", "Mode", "", ...
        "CurrentFilter", NaN, "DisplayFilter", NaN, ...
        "AutoOutput", NaN, "ActiveAutoOutput", NaN, ...
        "AutoShutoff", NaN, "OutputFormat", "", ...
        "InvertPolarity", false, "OmitPolarity", false, ...
        "Battery", "", "UnknownTokens", strings(1, 0), "Raw", record);
    if strlength(record) == 0
        return;
    end
    tokens = split(record, ";").';
    unknown = strings(1, numel(tokens));
    unknownCount = 0;
    for token = tokens
        value = upper(strip(token));
        if startsWith(value, "V")
            settings.Version = value;
        elseif any(value == ["LBF", "OZF", "KGF", "GF", "N", "MN", "KN"])
            settings.Unit = value;
        elseif any(value == ["CUR", "PT", "PC", "AM"])
            settings.Mode = value;
        elseif startsWith(value, "FLTC")
            settings.CurrentFilter = 2 ^ numericSuffix(value, "FLTC");
        elseif startsWith(value, "FLTP")
            settings.DisplayFilter = 2 ^ numericSuffix(value, "FLTP");
        elseif startsWith(value, "AOUT")
            settings.AutoOutput = numericSuffix(value, "AOUT");
            settings.ActiveAutoOutput = settings.AutoOutput;
        elseif startsWith(value, "AOFF")
            settings.AutoShutoff = numericSuffix(value, "AOFF");
        elseif any(value == ["FULL", "NUM"])
            settings.OutputFormat = value;
        elseif startsWith(value, "IPOL")
            settings.InvertPolarity = numericSuffix(value, "IPOL") == 1;
        elseif startsWith(value, "OPOL")
            settings.OmitPolarity = numericSuffix(value, "OPOL") == 1;
        elseif startsWith(value, "B")
            settings.Battery = value;
        else
            unknownCount = unknownCount + 1;
            unknown(unknownCount) = value;
        end
    end
    settings.UnknownTokens = unknown(1:unknownCount);
end

function value = numericSuffix(token, prefix)
value = str2double(extractAfter(token, strlength(prefix)));
end

function record = extractRecord(text)
record = "";
lines = split(replace(text, char(13), ""), newline);
for line = lines.'
    candidate = strip(line);
    if count(candidate, ";") >= 4 && contains(candidate, "AOUT", IgnoreCase=true)
        record = candidate;
        return;
    end
end
end

function text = responseText(raw)
if isempty(raw)
    text = "";
elseif ischar(raw)
    text = string(raw);
elseif isstring(raw) && isscalar(raw)
    text = raw;
elseif isnumeric(raw)
    text = string(native2unicode(uint8(raw(:).'), "UTF-8"));
else
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 settings response must be text or byte values.");
end
end
