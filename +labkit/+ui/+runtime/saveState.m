function filepath = saveState(fig, filepath)
%SAVESTATE Save a LabKit app state snapshot to a MAT file.
%
% App-facing contract:
%   filepath = labkit.ui.runtime.saveState(fig)
%   filepath = labkit.ui.runtime.saveState(fig, filepath)
%
% Inputs:
%   fig - LabKit app figure created by labkit.ui.runtime.run.
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
    if isfield(runtime.definition, 'contractVersion') && ...
            runtime.definition.contractVersion == 2
        labkitProject = createV2ProjectEnvelope(runtime);
        beforeReplace = [];
        if isstruct(runtime.request) && ...
                isfield(runtime.request, 'projectBeforeReplace')
            beforeReplace = runtime.request.projectBeforeReplace;
        end
        writeV2ProjectFile(filepath, labkitProject, beforeReplace);
        runtime = getAppRuntime(fig);
        runtime.document.path = filepath;
        runtime.document.dirty = false;
        runtime.document.modifiedAtUtc = ...
            labkitProject.document.modifiedAtUtc;
        runtime.document.envelope = labkitProject;
        setappdata(fig, appRuntimeKey(), runtime);
        updateV2DocumentTitle(fig);
    else
        snapshot = createSnapshot(runtime);
        save(filepath, 'snapshot');
    end
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
