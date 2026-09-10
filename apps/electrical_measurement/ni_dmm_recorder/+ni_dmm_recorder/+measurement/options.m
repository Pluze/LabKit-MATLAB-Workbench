function value = options()
%OPTIONS Return App labels and corresponding facade values.
value = struct();
value.ModeLabels = ["DC Voltage", "AC Voltage", "DC Current", ...
    "AC Current", "2-Wire Resistance", "4-Wire Resistance", "Diode"];
value.ModeValues = ["dc_voltage", "ac_voltage", "dc_current", ...
    "ac_current", "resistance_2wire", "resistance_4wire", "diode"];
value.RangeModes = ["Automatic", "Fixed"];
value.Digits = ["4.5", "5.5", "6.5"];
value.Rates = ["10 Hz", "20 Hz", "30 Hz", "40 Hz", "50 Hz"];
end
