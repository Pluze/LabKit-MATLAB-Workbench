function timeSec = timeToSeconds(timeValues)
%TIMETOSECONDS Convert timetable/table time values to seconds from start.

    if isduration(timeValues)
        timeSec = seconds(timeValues - timeValues(1));
    elseif isdatetime(timeValues)
        timeSec = seconds(timeValues - timeValues(1));
    elseif isnumeric(timeValues)
        timeSec = double(timeValues(:));
        timeSec = timeSec - timeSec(1);
    else
        n = numel(timeValues);
        timeSec = (0:n-1).';
    end
    timeSec = double(timeSec(:));
end
