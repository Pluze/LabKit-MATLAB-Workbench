function filepath = saveState(fig, filepath)
%SAVESTATE Save a Runtime V2 project to a MAT file.
%
% App-facing contract:
%   filepath = labkit.ui.runtime.saveState(fig)
%   filepath = labkit.ui.runtime.saveState(fig, filepath)
%
% Inputs:
%   fig - LabKit app figure created by labkit.ui.runtime.launch.
%   filepath - optional scalar text MAT-file target. When omitted, a save
%       dialog is shown.
%
% Output:
%   filepath - selected or supplied MAT-file path. Empty when the user
%       cancels the save dialog.
%
% Project contract:
%   Saves one `labkitProject` envelope containing only durable project data.

    if nargin < 2
        filepath = chooseProjectOutput();
        if strlength(filepath) == 0
            return;
        end
    else
        filepath = string(filepath);
    end
    runtime = getAppRuntime(fig);
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
    runtime.document.modifiedAtUtc = labkitProject.document.modifiedAtUtc;
    runtime.document.envelope = labkitProject;
    setappdata(fig, appRuntimeKey(), runtime);
    updateV2DocumentTitle(fig);
end

function filepath = chooseProjectOutput()
    [file, path] = uiputfile({'*.mat', 'MAT files (*.mat)'}, ...
        'Save LabKit Project');
    if isequal(file, 0) || isequal(path, 0)
        filepath = "";
    else
        filepath = string(fullfile(path, file));
    end
end
