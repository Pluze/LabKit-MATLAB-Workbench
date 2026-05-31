function timeSec = timeToSeconds(timeValues)
%TIMETOSECONDS Convert table/timetable time values to seconds from start.
%
% Inputs:
%   timeValues - duration, datetime, numeric vector, or other time-like
%                vector from a table/timetable.
%
% Output:
%   timeSec - double column vector. duration/datetime values are converted
%             relative to the first element, numeric values are shifted to
%             start at zero, and unsupported types fall back to 0-based
%             sample indices.

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
