function record = record(id, role, filepath)
%RECORD Create a file-list source value.
%
% Usage:
%   record = labkit.app.source.record(id,role,filepath)
%
% Description:
%   Creates the source value accepted by file-list bindings. It is live UI
%   state, not a portable archive format.
%
% Inputs:
%   id - Nonempty scalar text stable within the current App state.
%   role - Nonempty scalar semantic source role.
%   filepath - Nonempty scalar source path.
%
% Outputs:
%   record - Scalar source-list struct.
%
% Errors:
%   labkit:app:contract:InvalidValue - Text is malformed.
%
% Example:
%   source = labkit.app.source.record( ...
%       "image1","cropSource","image.png");
%   assert(source.id == "image1")
%
% See also labkit.app.CallbackContext
id = nonemptyText(id, "id");
role = nonemptyText(role, "role");
filepath = nonemptyText(filepath, "filepath");
record = struct("id", id, "role", role, "path", filepath);
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
