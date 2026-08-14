function period = ratePeriod(label)
%RATEPERIOD Convert an App sampling label to timer period in seconds.
switch string(label)
    case "5 Hz"
        period = 0.2;
    case "10 Hz"
        period = 0.1;
    case "20 Hz"
        period = 0.05;
    case "Maximum"
        period = 0.001;
    otherwise
        error("mark10_monitor:InvalidRate", ...
            "Unsupported Mark-10 sampling rate: %s.", string(label));
end
end
