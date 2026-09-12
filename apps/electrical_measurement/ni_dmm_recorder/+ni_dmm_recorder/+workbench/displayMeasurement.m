function display = displayMeasurement(values, sourceUnit)
%DISPLAYMEASUREMENT Select one engineering unit for NI-DMM presentation.
% Values remain in the device unit outside the visible workbench snapshot.
sourceUnit = string(sourceUnit);
display = struct("divisor", 1, "unit", sourceUnit);
if ~any(sourceUnit == ["V", "A", "ohm"])
    return;
end
if sourceUnit == "ohm"
    display.unit = string(char(hex2dec("03A9")));
end

finiteMagnitude = abs(double(values(isfinite(values))));
finiteMagnitude = finiteMagnitude(finiteMagnitude > 0);
if isempty(finiteMagnitude)
    return;
end
magnitude = max(finiteMagnitude);
divisors = [1e9, 1e6, 1e3, 1, 1e-3, 1e-6, 1e-9];
prefixes = ["G", "M", "k", "", "m", "u", "n"];
index = find(magnitude >= divisors, 1, "first");
if isempty(index)
    index = numel(divisors);
end
display.divisor = divisors(index);
display.unit = prefixes(index) + display.unit;
end
