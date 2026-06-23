function [filepath, cancelled, file, folder] = promptOutputFile(filterSpec, titleText, defaultPath, varargin)
%PROMPTOUTPUTFILE Prompt for an output file with LabKit-safe defaults.
%
% App-facing contract:
%   filepath = labkit.ui.app.promptOutputFile(filterSpec, title, defaultPath)
%   [filepath, cancelled] = labkit.ui.app.promptOutputFile(...)
%   [...] = labkit.ui.app.promptOutputFile(..., "Chooser", chooserFcn)
%
% Inputs:
%   filterSpec - file filter or default filename accepted by uiputfile.
%   titleText - dialog title. Defaults to "Save output file".
%   defaultPath - preferred output path or filename. Its folder is passed
%       through labkit.ui.app.defaultDialogFolder("output", folder).
%   Chooser - optional function handle for tests. It receives
%       (filterSpec, titleText, safeDefaultPath) and returns file, folder.
%
% Outputs:
%   filepath - selected full output path as a string scalar, or "" on cancel.
%   cancelled - true when the chooser was canceled.
%   file, folder - raw chooser file and folder outputs for callers that need
%       compatibility with uiputfile-style branching.

    if nargin < 1 || isempty(filterSpec)
        filterSpec = '*.*';
    end
    if nargin < 2 || isempty(titleText)
        titleText = "Save output file";
    end
    if nargin < 3
        defaultPath = "";
    end

    opts = parseOptions(varargin{:});
    safeDefaultPath = outputDefaultPath(defaultPath);
    chooserFilter = normalizeFilterSpec(filterSpec);

    [file, folder] = opts.chooser(chooserFilter, char(string(titleText)), ...
        char(safeDefaultPath));
    cancelled = isequal(file, 0) || isequal(folder, 0);
    if cancelled
        filepath = "";
        return;
    end

    filepath = string(fullfile(char(folder), char(file)));
    rememberOutputFolder(folder);
end

function opts = parseOptions(varargin)
    opts = struct('chooser', @uiputfile);
    if mod(numel(varargin), 2) ~= 0
        error('labkit:ui:app:InvalidPromptOutputFileOptions', ...
            'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        name = lower(strtrim(string(varargin{k})));
        value = varargin{k + 1};
        switch name
            case "chooser"
                if ~isa(value, 'function_handle')
                    error('labkit:ui:app:InvalidPromptOutputFileOptions', ...
                        'Chooser must be a function handle.');
                end
                opts.chooser = value;
            otherwise
                error('labkit:ui:app:InvalidPromptOutputFileOptions', ...
                    'Unsupported option "%s".', name);
        end
    end
end

function filterSpec = normalizeFilterSpec(filterSpec)
    if isstring(filterSpec) && isscalar(filterSpec)
        filterSpec = char(filterSpec);
    end
end

function pathValue = outputDefaultPath(defaultPath)
    defaultPath = string(defaultPath);
    if isempty(defaultPath) || strlength(strtrim(defaultPath(1))) == 0
        folder = labkit.ui.app.defaultDialogFolder("output");
        pathValue = string(fullfile(folder, 'output'));
        return;
    end

    defaultPath = strtrim(defaultPath(1));
    [folder, name, ext] = fileparts(char(defaultPath));
    filename = string(name) + string(ext);
    if strlength(filename) == 0
        filename = "output";
    end
    safeFolder = labkit.ui.app.defaultDialogFolder("output", folder);
    pathValue = string(fullfile(safeFolder, char(filename)));
end

function rememberOutputFolder(folder)
    if isempty(folder) || isequal(folder, 0)
        return;
    end
    folder = string(folder);
    if isempty(folder) || strlength(folder(1)) == 0 || exist(char(folder(1)), 'dir') ~= 7
        return;
    end
    setpref('LabKit', 'LastOutputFolder', char(folder(1)));
end
