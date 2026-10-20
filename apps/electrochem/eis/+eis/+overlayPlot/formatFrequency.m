function label = formatFrequency(frequency)
% Four significant digits with readable frequency units, never exponent text.
units = ["Hz" "kHz" "MHz" "GHz" "THz"];
unitIndex = min(numel(units), max(1, floor(log10(frequency)/3)+1));
value = frequency / 1000^(unitIndex-1);
decimals = max(0, 3-floor(log10(value)));
value = round(value, decimals);
if value >= 1000 && unitIndex < numel(units)
    value = value / 1000;
    unitIndex = unitIndex + 1;
    decimals = max(0, 3-floor(log10(value)));
end
number = string(sprintf('%.*f', decimals, value));
if contains(number, ".")
    number = regexprep(number, '0+$', '');
    number = regexprep(number, '\.$', '');
end
label = number + " " + units(unitIndex);
end
