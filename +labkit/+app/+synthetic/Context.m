classdef (Sealed) Context
    %CONTEXT Provide bounded folders for anonymous synthetic inputs.
    %
    % Usage:
    %   context = labkit.app.synthetic.Context(rootFolder)
    %   filepath = context.samplePath(relativePath)
    %   filepath = context.outputPath(relativePath)
    %   record = context.sourceRecord(id,role,filepath,required)
    %   artifact = context.artifact(id,role,filepath,Name=Value)
    %
    % Description:
    %   Context creates one synthetic-input root with samples and outputs
    %   children. App-owned BuildSyntheticSample callbacks may write only
    %   anonymous synthetic files beneath these folders. The value does not
    %   expose a runtime, recorder, project store, or UI object.
    %
    % Inputs:
    %   rootFolder - Nonempty scalar folder dedicated to one generated pack.
    %   relativePath - Nonempty child path without an absolute root, empty
    %       segment, current segment, or parent traversal.
    %   id - Stable portable-source identifier.
    %   role - Stable portable-source role.
    %   filepath - Path returned by samplePath.
    %   required - Logical scalar source requirement.
    %
    % Outputs:
    %   context - Immutable synthetic-input context.
    %   filepath - Absolute path bounded by SampleFolder or OutputFolder.
    %   record - Portable source value from
    %       labkit.app.project.sourceRecord.
    %   artifact - Typed synthetic artifact whose relative path is derived
    %       from a filepath beneath RootFolder.
    %
    % Errors:
    %   labkit:app:contract:InvalidValue - A folder, relative path, or source
    %       argument is malformed.
    %   MATLAB filesystem errors propagate when the synthetic folders cannot
    %       be created.
    %
    % Typical Call:
    %   context = labkit.app.synthetic.Context(tempname);
    %   filepath = context.samplePath("input.csv");
    %
    % See also labkit.app.synthetic.Artifact,
    %   labkit.app.synthetic.Pack,
    %   labkit.app.project.sourceRecord

    properties (SetAccess = immutable)
        RootFolder (1, 1) string
        SampleFolder (1, 1) string
        OutputFolder (1, 1) string
    end

    methods
        function obj = Context(rootFolder)
            rootFolder = nonemptyText(rootFolder, "RootFolder");
            obj.RootFolder = rootFolder;
            obj.SampleFolder = string(fullfile( ...
                char(rootFolder), "samples"));
            obj.OutputFolder = string(fullfile( ...
                char(rootFolder), "outputs"));
            ensureFolder(obj.RootFolder);
            ensureFolder(obj.SampleFolder);
            ensureFolder(obj.OutputFolder);
        end

        function filepath = samplePath(obj, relativePath)
            filepath = boundedPath(obj.SampleFolder, relativePath);
        end

        function filepath = outputPath(obj, relativePath)
            filepath = boundedPath(obj.OutputFolder, relativePath);
        end

        function record = sourceRecord(~, id, role, filepath, required)
            if nargin < 5
                required = true;
            end
            record = labkit.app.project.sourceRecord( ...
                id, role, filepath, required);
        end

        function artifact = artifact(obj, id, role, filepath, varargin)
            relativePath = relativeArtifactPath( ...
                obj.RootFolder, filepath);
            artifact = labkit.app.synthetic.Artifact( ...
                id, role, relativePath, varargin{:});
        end
    end
end

function filepath = boundedPath(folder, relativePath)
relativePath = replace(nonemptyText(relativePath, "relativePath"), "\", "/");
if startsWith(relativePath, "/") || startsWith(relativePath, "//") || ...
        ~isempty(regexp(char(relativePath), '^[A-Za-z]:', "once"))
    invalid("relativePath must be folder-relative.");
end
parts = split(relativePath, "/");
if any(parts == ["", ".", ".."], "all")
    invalid("relativePath must not traverse the synthetic folder.");
end
partCells = cellstr(parts);
filepath = string(fullfile(char(folder), partCells{:}));
parent = string(fileparts(filepath));
ensureFolder(parent);
end

function ensureFolder(folder)
if exist(char(folder), "dir") ~= 7
    mkdir(char(folder));
end
end

function relativePath = relativeArtifactPath(root, filepath)
root = normalizedAbsolutePath(root, "RootFolder");
filepath = normalizedAbsolutePath(filepath, "filepath");
rootPrefix = root + "/";
if ispc
    inside = startsWith(lower(filepath), lower(rootPrefix));
else
    inside = startsWith(filepath, rootPrefix);
end
if ~inside
    invalid("filepath must remain beneath RootFolder.");
end
relativePath = extractAfter(filepath, strlength(rootPrefix));
if strlength(relativePath) == 0
    invalid("filepath must name a child artifact.");
end
end

function value = normalizedAbsolutePath(value, name)
value = replace(nonemptyText(value, name), "\", "/");
if ~isAbsolutePath(value)
    value = replace(string(fullfile(pwd, char(value))), "\", "/");
end
while endsWith(value, "/") && value ~= "/" && ...
        isempty(regexp(char(value), '^[A-Za-z]:/$', "once"))
    value = extractBefore(value, strlength(value));
end
end

function tf = isAbsolutePath(value)
tf = startsWith(value, "/") || startsWith(value, "//") || ...
    ~isempty(regexp(char(value), '^[A-Za-z]:/', "once"));
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
error("labkit:app:contract:InvalidValue", ...
    "Synthetic Context " + message, varargin{:});
end
