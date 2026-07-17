function filepath = loadState(fig, filepath)
%LOADSTATE Load a compatible Runtime V2 project or declared legacy import.
%
% Usage:
%   filepath = labkit.ui.runtime.loadState(fig)
%   filepath = labkit.ui.runtime.loadState(fig, filepath)
%
% Inputs:
%   fig - Live app figure created by labkit.ui.runtime.launch.
%   filepath - MAT-file to load. When omitted, MATLAB opens a file-selection
%       dialog.
%
% Outputs:
%   filepath - Selected or supplied path as a string scalar, or "" when the
%       user cancels the dialog.
%
% Description:
%   loadState accepts a current labkitProject envelope, an older Runtime V2
%   snapshot, or a MAT-file variable named in Project.LegacyImports. Current
%   payloads are migrated one version at a time, validated, and checked for
%   required source files. When automatic source resolution fails, the runtime
%   identifies each missing file and lets the user locate it or cancel. A fresh
%   session is then created and optional resume data is applied. The live app
%   changes only after the complete candidate and its first presentation
%   succeed; an error or cancellation leaves the previous project and view
%   intact. Relinked or migrated documents open as unsaved work. Saving them
%   writes the current labkitProject format rather than the imported old format.
%
% Errors:
%   labkit:ui:runtime:ProjectLoadCancelled - Required-source relinking was
%       cancelled. The live project remains unchanged.
%   Project-format, validation, migration, source-decoding, and presentation
%       errors are rethrown after the Runtime records diagnostic context. The
%       live project remains unchanged.
%
% Typical Call:
%   loadedFile = labkit.ui.runtime.loadState(fig, "analysis.project.mat");
%
% See also labkit.ui.runtime.saveState, labkit.ui.runtime.define

    if nargin < 2
        filepath = chooseProjectInput();
        if strlength(filepath) == 0
            return;
        end
    else
        filepath = string(filepath);
    end
    try
        restoreV2Project(fig, filepath);
    catch ME
        reportLoadFailure(fig, filepath, ME);
        rethrow(ME);
    end
end

function filepath = chooseProjectInput()
    [file, path] = uigetfile({'*.mat', 'MAT files (*.mat)'}, ...
        'Load LabKit Project');
    if isequal(file, 0) || isequal(path, 0)
        filepath = "";
    else
        filepath = string(fullfile(path, file));
    end
end

function reportLoadFailure(fig, filepath, exception)
    if string(exception.identifier) == ...
            "labkit:ui:runtime:ProjectLoadCancelled"
        return;
    end
    try
        runtime = getAppRuntime(fig);
        debug = runtime.debug;
        if isstruct(debug) && isfield(debug, 'reportException') && ...
                isa(debug.reportException, 'function_handle')
            [~, name, extension] = fileparts(filepath);
            context = sprintf('project load failed for %s%s', ...
                name, extension);
            debug.reportException(char(string(runtime.definition.id)), ...
                context, exception);
        end
    catch
        % Diagnostic reporting must not replace the original load failure.
    end
end
