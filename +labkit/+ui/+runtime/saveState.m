function filepath = saveState(fig, filepath)
%SAVESTATE Save a Runtime V2 project to a MAT file.
%
% Usage:
%   filepath = labkit.ui.runtime.saveState(fig)
%   filepath = labkit.ui.runtime.saveState(fig, filepath)
%
% Inputs:
%   fig - Live app figure created by labkit.ui.runtime.launch.
%   filepath - Destination MAT-file. When omitted, MATLAB opens a save dialog.
%       The parent folder must already exist.
%
% Outputs:
%   filepath - Selected or supplied path as a string scalar, or "" when the
%       user cancels the dialog.
%
% Description:
%   saveState writes one variable named labkitProject. The envelope contains
%   durable project data, schema and producer versions, source references,
%   document identity and revision information, and optional resume data.
%   Session caches and live graphics handles are not saved. Unknown additive
%   envelope fields from a previously loaded project are preserved.
%
%   The file is first written and verified at a temporary path in the same
%   folder. It replaces the destination only after the read-back comparison
%   succeeds, so a failure before replacement leaves an existing project file
%   unchanged. After a successful save the app records the new path, clears its
%   dirty flag, and updates the window title.
%
% Typical Call:
%   savedFile = labkit.ui.runtime.saveState(fig, "analysis.project.mat");
%
% See also labkit.ui.runtime.loadState

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
