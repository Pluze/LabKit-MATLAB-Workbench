function values = paths(records)
%PATHS Return paths from a live source collection.
%
% Usage:
%   values = labkit.app.source.paths(records)
%
% Inputs:
%   records - Struct array created by labkit.app.source.record.
%
% Outputs:
%   values - Column string array in source-list order.
%
% Errors:
%   labkit:app:contract:InvalidValue - Records are malformed.
%
% Example:
%   source = labkit.app.source.record("image1", "image", "image.png");
%   assert(labkit.app.source.paths(source) == "image.png")
%
% See also labkit.app.source.record, labkit.app.source.emptyRecords
if isempty(records)
    if ~isstruct(records)
        invalid();
    end
    values = strings(0, 1);
    return
end
if ~isstruct(records)
    invalid();
end
values = strings(numel(records), 1);
for k = 1:numel(records)
    record = records(k);
    if ~isscalar(record) || ...
            ~isequal(string(fieldnames(record)), ["id"; "role"; "path"]) || ...
            ~(ischar(record.path) || ...
              (isstring(record.path) && isscalar(record.path))) || ...
            strlength(string(record.path)) == 0
        invalid();
    end
    values(k) = string(record.path);
end
end

function invalid()
error("labkit:app:contract:InvalidValue", ...
    "Source records must contain canonical id, role, and path fields.");
end
