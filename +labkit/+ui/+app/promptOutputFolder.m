function [folder, cancelled] = promptOutputFolder(titleText, defaultFolder, varargin)
%PROMPTOUTPUTFOLDER Prompt for an output folder with LabKit-safe defaults.
%
% App-facing contract:
%   folder = labkit.ui.app.promptOutputFolder(titleText, defaultFolder)
%   [folder, cancelled] = labkit.ui.app.promptOutputFolder(...)
%   [...] = labkit.ui.app.promptOutputFolder(..., "Chooser", chooserFcn)
%
% Inputs:
%   titleText - dialog title. Defaults to "Select output folder".
%   defaultFolder - preferred output folder. It is passed through
%       labkit.ui.app.defaultDialogFolder("output", defaultFolder).
%   Chooser - optional function handle for tests. It receives
%       (safeDefaultFolder, titleText) and returns a folder path or 0.
%
% Outputs:
%   folder - selected folder as a string scalar, or "" on cancel.
%   cancelled - true when the chooser was canceled.

    if nargin < 1 || isempty(titleText)
        titleText = "Select output folder";
    end
    if nargin < 2
        defaultFolder = "";
    end

    opts = parseOptions(varargin{:});
    safeDefaultFolder = labkit.ui.app.defaultDialogFolder("output", defaultFolder);
    rawFolder = opts.chooser(safeDefaultFolder, char(string(titleText)));
    cancelled = isequal(rawFolder, 0);
    if cancelled
        folder = "";
        return;
    end

    folder = string(rawFolder);
    if isempty(folder) || strlength(strtrim(folder(1))) == 0
        folder = "";
        cancelled = true;
        return;
    end
    folder = strtrim(folder(1));
    rememberOutputFolder(folder);
end

function opts = parseOptions(varargin)
    opts = struct('chooser', @uigetdir);
    if mod(numel(varargin), 2) ~= 0
        error('labkit:ui:app:InvalidPromptOutputFolderOptions', ...
            'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        name = lower(strtrim(string(varargin{k})));
        value = varargin{k + 1};
        switch name
            case "chooser"
                if ~isa(value, 'function_handle')
                    error('labkit:ui:app:InvalidPromptOutputFolderOptions', ...
                        'Chooser must be a function handle.');
                end
                opts.chooser = value;
            otherwise
                error('labkit:ui:app:InvalidPromptOutputFolderOptions', ...
                    'Unsupported option "%s".', name);
        end
    end
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
