function records = emptySourceRecords()
%EMPTYSOURCERECORDS Create an empty portable source collection.
%
% Usage:
%   records = labkit.app.project.emptySourceRecords()
%
% Description:
%   Returns a zero-row struct collection with the same durable field shape
%   as labkit.app.project.sourceRecord. App project factories use this value
%   so the first file selection can assign a portable source without exposing
%   or duplicating its field schema.
%
% Outputs:
%   records - Empty column collection of portable source records.
%
% Example:
%   project.inputs.sources = labkit.app.project.emptySourceRecords();
%   assert(isempty(project.inputs.sources))
%
% See also labkit.app.project.sourceRecord,
%   labkit.app.project.Schema

prototype = labkit.app.project.sourceRecord( ...
    "placeholder", "placeholder", "placeholder", true);
records = repmat(prototype, 0, 1);
end
