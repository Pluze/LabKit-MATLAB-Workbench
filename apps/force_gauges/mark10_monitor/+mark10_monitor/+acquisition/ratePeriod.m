function period = ratePeriod(label)
%RATEPERIOD Convert an App sampling label to timer period in seconds.
switch string(label)
    case "10 Hz"
        period = 0.1;
    case "20 Hz"
        period = 0.05;
    case "30 Hz"
        period = 1 / 30;
    case "40 Hz"
        period = 0.025;
    case "50 Hz"
        period = 0.02;
    otherwise
        error("mark10_monitor:InvalidRate", ...
            "Unsupported Mark-10 sampling rate: %s.", string(label));
end
end
