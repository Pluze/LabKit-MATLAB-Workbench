classdef (Sealed) File
    %RESULTOUTPUT Declare one validated result-package output.
    %
    % Usage:
    %   output = labkit.app.result.File(id, role, relativePath, Name=Value)
    %
    % Description:
    %   File records App-owned output identity and media semantics.
    %   Runtime result writing later resolves the relative path, file size,
    %   checksum, and aggregate manifest status.
    %
    % Inputs:
    %   id - Nonempty scalar text unique within one Result.
    %   role - Nonempty scalar text describing output purpose.
    %   relativePath - Nonempty package-relative path without traversal.
    %
    % Optional Name-Value Arguments:
    %   MediaType - Nonempty media-type scalar text. Default:
    %       "application/octet-stream".
    %   Status - "success", "failed", or "skipped". Default: "success".
    %   Message - Scalar reader-facing status text. Default: empty.
    %   Warnings - Row string or cellstr array. Default: empty.
    %
    % Outputs:
    %   output - Immutable labkit.app.result.File value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is unknown, duplicated,
    %       or unpaired.
    %   labkit:app:contract:InvalidValue - Text, path, status, or warnings are
    %       malformed.
    %
    % Example:
    %   output = labkit.app.result.File( ...
    %       "summary", "primary", "summary.csv", MediaType="text/csv");
    %   assert(output.Status == "success")
    %
    % See also labkit.app.result.Package, labkit.app.CallbackContext

    properties (SetAccess = immutable)
        Id (1, 1) string
        Role (1, 1) string
        RelativePath (1, 1) string
        MediaType (1, 1) string
        Status (1, 1) string
        Message (1, 1) string
        Warnings (1, :) string
    end

    methods
        function obj = File(id, role, relativePath, varargin)
            names = ["MediaType", "Status", "Message", "Warnings"];
            options = labkit.app.internal.contract.OptionParser.parse( ...
                "labkit.app.result.File", names, varargin{:});
            obj.Id = nonemptyText(id, "id");
            obj.Role = nonemptyText(role, "role");
            obj.RelativePath = relativePathValue(relativePath);
            obj.MediaType = nonemptyText(optionValue(options, ...
                "MediaType", "application/octet-stream"), "MediaType");
            obj.Status = statusValue( ...
                optionValue(options, "Status", "success"));
            obj.Message = scalarText( ...
                optionValue(options, "Message", ""), "Message");
            obj.Warnings = textRow( ...
                optionValue(options, "Warnings", strings(1, 0)), ...
                "Warnings");
        end
    end
end

function value = relativePathValue(value)
    value = replace(nonemptyText(value, "relativePath"), "\", "/");
    if startsWith(value, "/") || startsWith(value, "//") || ...
            ~isempty(regexp(char(value), '^[A-Za-z]:', "once"))
        error("labkit:app:contract:InvalidValue", ...
            "File relativePath must be package-relative.");
    end
    parts = split(value, "/");
    if any(parts == ["", ".", ".."], "all")
        error("labkit:app:contract:InvalidValue", ...
            "File relativePath must not traverse package boundaries.");
    end
    value = join(parts, "/");
end

function value = statusValue(value)
    value = nonemptyText(value, "Status");
    if ~any(value == ["success", "failed", "skipped"])
        error("labkit:app:contract:InvalidValue", ...
            "File Status must be success, failed, or skipped.");
    end
end

function value = nonemptyText(value, name)
    value = scalarText(value, name);
    if strlength(value) == 0
        error("labkit:app:contract:InvalidValue", ...
            "File %s must be nonempty.", name);
    end
end

function value = scalarText(value, name)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:app:contract:InvalidValue", ...
            "File %s must be scalar text.", name);
    end
    value = string(value);
end

function values = textRow(values, name)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:app:contract:InvalidValue", ...
            "File %s must be text.", name);
    end
    values = reshape(values, 1, []);
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end
