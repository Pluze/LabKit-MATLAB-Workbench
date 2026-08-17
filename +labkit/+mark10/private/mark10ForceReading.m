function reading = mark10ForceReading(raw)
% Parse one Series 5 force response and derive its displayed SI resolution.
text = strip(mark10ResponseText(raw));
token = regexp(char(text), ...
    '^([-+]?\d+(?:\.\d+)?)\s*([A-Za-z]+)$', 'tokens', 'once');
reading = struct("Value", NaN, "Unit", "", "Force_N", NaN, ...
    "Resolution_N", NaN, "RawText", text, "Valid", false);
if isempty(token)
    return;
end
reading.Value = str2double(token{1});
reading.Unit = string(token{2});
reading.Force_N = convertForce(reading.Value, reading.Unit);
reading.Resolution_N = convertForce(decimalResolution(token{1}), reading.Unit);
reading.Valid = isfinite(reading.Force_N);
end

function value = decimalResolution(token)
parts = split(string(token), ".");
if isscalar(parts)
    value = 1;
else
    value = 10 ^ (-strlength(parts(2)));
end
end

function value = convertForce(value, unit)
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
