function record = sourceRecord(id, role, filepath, required)
%SOURCERECORD Create a portable source value during project migration.
%
% Usage:
%   record = labkit.app.project.sourceRecord(id,role,filepath)
%   record = labkit.app.project.sourceRecord(id,role,filepath,required)
%
% Description:
%   Creates the opaque durable source value accepted by App project schemas.
%   Use this pure constructor only while creating or migrating payloads.
%   Runtime callbacks resolve paths through CallbackContext.
%
% Inputs:
%   id - Nonempty scalar text stable within the project.
%   role - Nonempty scalar semantic source role.
%   filepath - Nonempty scalar source path, or an existing scalar opaque
%       reference struct during legacy migration.
%   required - Optional logical scalar relinking requirement. Default: true.
%
% Outputs:
%   record - Scalar portable source struct owned by the App framework.
%
% Errors:
%   labkit:app:contract:InvalidValue - Text or required is malformed.
%
% Example:
%   source = labkit.app.project.sourceRecord( ...
%       "image1","cropSource","image.png");
%   assert(source.id == "image1")
%
% See also labkit.app.CallbackContext, labkit.app.project.Schema
if nargin < 4
    required = true;
end
id = nonemptyText(id, "id");
role = nonemptyText(role, "role");
if ~(islogical(required) && isscalar(required))
    invalid("required must be a logical scalar.");
end
if isstruct(filepath)
    reference = portableReference(filepath);
else
    filepath = nonemptyText(filepath, "filepath");
    [~, name, extension] = fileparts(filepath);
    reference = struct("schemaVersion", 1, "relativePath", "", ...
        "originalPath", filepath, "fileName", string(name) + string(extension));
end
record = struct("id", id, "required", required, "role", role, ...
    "reference", {reference});
end

function reference = portableReference(value)
required = ["schemaVersion", "relativePath", "originalPath", "fileName"];
if ~isscalar(value) || ~all(isfield(value, cellstr(required)))
    invalid("filepath reference must be a scalar portable source reference.");
end
reference = struct( ...
    "schemaVersion", double(value.schemaVersion), ...
    "relativePath", string(value.relativePath), ...
    "originalPath", string(value.originalPath), ...
    "fileName", string(value.fileName));
if ~(isscalar(reference.schemaVersion) && ...
        isfinite(reference.schemaVersion) && reference.schemaVersion == 1) || ...
        ~all(arrayfun(@(name) isscalar(reference.(name)), ...
        ["relativePath", "originalPath", "fileName"]))
    invalid("filepath reference is malformed.");
end
end

function value = nonemptyText(value, name)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    invalid("%s must be scalar text.", name);
end
value = string(value);
if strlength(value) == 0
    invalid("%s must be nonempty.", name);
end
end

function invalid(message, varargin)
error("labkit:app:contract:InvalidValue", message, varargin{:});
end
