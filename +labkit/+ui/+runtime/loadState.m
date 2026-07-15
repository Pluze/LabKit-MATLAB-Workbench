function filepath = loadState(fig, filepath)
%LOADSTATE Load a compatible Runtime V2 project or declared legacy import.
%
% App-facing contract:
%   filepath = labkit.ui.runtime.loadState(fig)
%   filepath = labkit.ui.runtime.loadState(fig, filepath)
%
% Inputs:
%   fig - LabKit app figure created by labkit.ui.runtime.launch.
%   filepath - optional scalar text MAT-file path. When omitted, an open
%       dialog is shown.
%
% Output:
%   filepath - selected or supplied MAT-file path. Empty when the user
%       cancels the open dialog.
%
% Runtime behavior:
%   Validates and resolves the complete candidate before atomically replacing
%   project/session state. Named legacy imports are read-only.

    if nargin < 2
        filepath = chooseProjectInput();
        if strlength(filepath) == 0
            return;
        end
    else
        filepath = string(filepath);
    end
    restoreV2Project(fig, filepath);
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
