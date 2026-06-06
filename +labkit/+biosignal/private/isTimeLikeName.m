% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function tf = isTimeLikeName(name)
%ISTIMELIKENAME Identify table column names that should drive time inference.
%
% Expected caller:
%   readDelimitedTable and inferTableTime.
%
% Inputs/outputs:
%   String-like column/header token. Returns true for explicit time,
%   timestamp, and common unit aliases.
%
% Side effects:
%   None.

    clean = lower(regexprep(char(name), '[^a-z0-9]+', ''));
    tf = contains(clean, 'time') || contains(clean, 'timestamp') || ...
        contains(clean, 'seconds') || contains(clean, 'millisecond') || ...
        contains(clean, 'microsecond') || contains(clean, 'nanosecond') || ...
        any(strcmp(clean, {'t', 'sec', 'secs', 'ms', 'msec', 'us', 'usec', 'ns'}));
end
