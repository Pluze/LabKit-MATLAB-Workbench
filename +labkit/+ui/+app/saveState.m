function filepath = saveState(fig, filepath)
%SAVESTATE Save a LabKit app state snapshot to a MAT file.
%
% App-facing contract:
%   filepath = labkit.ui.app.saveState(fig)
%   filepath = labkit.ui.app.saveState(fig, filepath)
%
% Inputs:
%   fig - LabKit app figure created by labkit.ui.app.run.
%   filepath - optional scalar text MAT-file target. When omitted, a save
%       dialog is shown.
%
% Output:
%   filepath - selected or supplied MAT-file path. Empty when the user
%       cancels the save dialog.
%
% Snapshot contract:
%   Saves one variable named `snapshot`. The snapshot contains app identity,
%   LabKit UI version, MATLAB release/platform, optional app snapshot schema
%   version, and serialized semantic app state. Runtime handles, callbacks,
%   UI registry structs, debug contexts, and function handles are rejected.

    if nargin < 2
        filepath = chooseSnapshotOutput();
        if strlength(filepath) == 0
            return;
        end
    else
        filepath = string(filepath);
    end
    runtime = getAppRuntime(fig);
    snapshot = createSnapshot(runtime);
    save(filepath, 'snapshot');
end

function filepath = chooseSnapshotOutput()
    [file, path] = uiputfile({'*.mat', 'MAT files (*.mat)'}, ...
        'Save LabKit State Snapshot');
    if isequal(file, 0) || isequal(path, 0)
        filepath = "";
    else
        filepath = string(fullfile(path, file));
    end
end
