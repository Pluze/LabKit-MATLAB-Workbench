function sources = emptySourceRecords()
%EMPTYSOURCERECORDS Create an empty canonical Runtime V2 source array.
%
% App-facing contract:
%   sources = labkit.ui.runtime.emptySourceRecords()
%
% Inputs:
%   None.
%
% Outputs:
%   sources - 0-by-1 struct array with the canonical Runtime V2 source-record
%       fields. Assign it to project.inputs source collections when creating
%       a new durable project.
%
% Example:
%   project.inputs = struct( ...
%       "sources", labkit.ui.runtime.emptySourceRecords());

    sources = repmat(canonicalSourceRecord("", "", "", true), 0, 1);
end
