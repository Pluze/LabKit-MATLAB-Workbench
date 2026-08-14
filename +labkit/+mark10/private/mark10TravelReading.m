function reading = mark10TravelReading(raw)
% Parse one ESM303 travel response and convert it to millimeters.
text = strip(mark10ResponseText(raw));
token = regexp(char(text), ...
    '^([-+]?\d+(?:\.\d+)?)\s*(mm|in)$', ...
    'tokens', 'once', 'ignorecase');
reading = struct("Value", NaN, "Unit", "", "Travel_mm", NaN, ...
    "RawText", text, "Valid", false);
if isempty(token)
    return;
end
reading.Value = str2double(token{1});
reading.Unit = string(token{2});
if lower(reading.Unit) == "mm"
    reading.Travel_mm = reading.Value;
elseif lower(reading.Unit) == "in"
    reading.Travel_mm = reading.Value * 25.4;
end
reading.Valid = isfinite(reading.Travel_mm);
end
