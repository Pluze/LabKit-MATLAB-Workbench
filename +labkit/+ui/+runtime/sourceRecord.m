function source = sourceRecord(id, role, filepath, required)
%SOURCERECORD Create one canonical Runtime V2 external-source record.
%
% Usage:
%   source = labkit.ui.runtime.sourceRecord(id, role, filepath)
%   source = labkit.ui.runtime.sourceRecord(id, role, filepath, required)
%
% Inputs:
%   id - Nonempty scalar text identifying this source within one App project.
%       The ID is App-owned, stable across saves, and unique in the project's
%       source collection. It is not derived from the filename.
%   role - Nonempty scalar text describing the source's App-owned semantic
%       role, such as "referenceImage" or "numericTrace".
%   filepath - Nonempty scalar file path as char or string. Runtime V2 stores
%       it in its private portable-reference representation.
%   required - Optional scalar logical flag. True means project loading must
%       resolve this source before committing the loaded state. Default: true.
%
% Outputs:
%   source - Scalar struct with stable App-facing id, required, and role
%       fields plus a runtime-owned reference field. Preserve reference but do
%       not read or construct its nested fields; use sourcePaths to obtain the
%       current resolved path.
%
% Description:
%   Use this GUI-free factory in project creation, migration, import, and
%   tests. Runtime action handlers may equivalently call the injected
%   services.project.sourceRecord service. Both entry points produce the same
%   canonical record.
%
% Errors:
%   labkit:ui:runtime:InvalidSourceRecords - An ID, role, filepath, or required
%       value is empty, nonscalar, or has the wrong type.
%
% Example:
%   source = labkit.ui.runtime.sourceRecord( ...
%       "reference", "referenceImage", "reference.tif");
%   assert(labkit.ui.runtime.sourcePaths(source) == "reference.tif")
%
% See also labkit.ui.runtime.sourcePaths,
%   labkit.ui.runtime.emptySourceRecords, labkit.ui.runtime.define

    if nargin < 4
        required = true;
    end
    validateText(id, 'Project source id');
    validateText(role, 'Project source role');
    validateText(filepath, 'Project source filepath');
    if ~(islogical(required) || isnumeric(required)) || ...
            ~isscalar(required) || ~isfinite(double(required)) || ...
            ~any(double(required) == [0 1])
        invalid('Project source required flag must be scalar logical.');
    end
    source = canonicalSourceRecord( ...
        string(id), string(role), string(filepath), logical(required));
end

function validateText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
            strlength(string(value)) == 0
        invalid('%s must be nonempty scalar text.', label);
    end
end

function invalid(message, varargin)
    error('labkit:ui:runtime:InvalidSourceRecords', message, varargin{:});
end
