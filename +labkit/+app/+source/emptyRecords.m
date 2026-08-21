function records = emptyRecords()
%EMPTYRECORDS Create an empty file-list source collection.
%
% Usage:
%   records = labkit.app.source.emptyRecords()
%
% Description:
%   Returns a zero-row struct collection with the same live field shape as
%   labkit.app.source.record.
%
% Outputs:
%   records - Empty column collection of source records.
%
% Failure Behavior:
%   None - The function accepts no inputs and returns the canonical empty
%   collection deterministically.
%
% Example:
%   state.inputs.sources = labkit.app.source.emptyRecords();
%   assert(isempty(state.inputs.sources))
%
% See also labkit.app.source.record

prototype = labkit.app.source.record( ...
    "placeholder", "placeholder", "placeholder", true);
records = repmat(prototype, 0, 1);
end
