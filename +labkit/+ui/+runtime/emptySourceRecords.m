function sources = emptySourceRecords()
%EMPTYSOURCERECORDS Create an empty Runtime V2 source array.
%
% Usage:
%   sources = labkit.ui.runtime.emptySourceRecords()
%
% Outputs:
%   sources - 0-by-1 struct array with id, required, role, and reference
%       fields. reference contains schemaVersion, relativePath, originalPath,
%       and fileName.
%
% Source Record Fields:
%   id - Stable source identifier chosen by the app.
%   required - Logical value indicating whether project load must resolve the
%       file before committing the project.
%   role - App-defined description of how the source is used.
%   reference - Runtime-owned portable reference with schemaVersion,
%       relativePath, originalPath, and fileName fields. Apps normally obtain
%       populated records from the injected services.project.sourceRecord.
%
% Description:
%   Use this value to initialize project.inputs.sources when a new project has
%   no external files. Starting with the expected empty shape avoids struct
%   assignment errors when source records are added later.
%
% Example:
%   project.inputs = struct( ...
%       "sources", labkit.ui.runtime.emptySourceRecords());
%   assert(isempty(project.inputs.sources))
%
% See also labkit.ui.runtime.define

    reference = struct("schemaVersion", 1, "relativePath", "", ...
        "originalPath", "", "fileName", "");
    prototype = struct("id", "", "required", true, "role", "", ...
        "reference", reference);
    sources = repmat(prototype, 0, 1);
end
