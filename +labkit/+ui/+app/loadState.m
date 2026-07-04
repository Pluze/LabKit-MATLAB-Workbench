function filepath = loadState(fig, filepath)
%LOADSTATE Load a compatible LabKit app state snapshot from a MAT file.
%
% App-facing contract:
%   filepath = labkit.ui.app.loadState(fig)
%   filepath = labkit.ui.app.loadState(fig, filepath)
%
% Inputs:
%   fig - LabKit app figure created by labkit.ui.app.run.
%   filepath - optional scalar text MAT-file path. When omitted, an open
%       dialog is shown.
%
% Output:
%   filepath - selected or supplied MAT-file path. Empty when the user
%       cancels the open dialog.
%
% Runtime behavior:
%   Loads only a variable named `snapshot`, validates schema, app id,
%   LabKit UI version, MATLAB release/platform, and optional app snapshot
%   version before mutating runtime state. Failed loads restore the previous
%   app state and visible render.

    if nargin < 2
        filepath = chooseSnapshotInput();
        if strlength(filepath) == 0
            return;
        end
    else
        filepath = string(filepath);
    end
    restoreSnapshot(fig, filepath);
end

function filepath = chooseSnapshotInput()
    [file, path] = uigetfile({'*.mat', 'MAT files (*.mat)'}, ...
        'Load LabKit State Snapshot');
    if isequal(file, 0) || isequal(path, 0)
        filepath = "";
    else
        filepath = string(fullfile(path, file));
    end
end
