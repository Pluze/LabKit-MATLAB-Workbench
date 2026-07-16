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
%   required source files. A fresh session is then created and optional resume
%   data is applied. The live app changes only after the complete candidate and
%   its first presentation succeed; an error leaves the previous project and
%   view intact. Legacy formats can be opened but are never written back in
%   their old format.
%
% Typical Call:
%   loadedFile = labkit.ui.runtime.loadState(fig, "analysis.project.mat");
%
% See also labkit.ui.runtime.saveState,
%   labkit.ui.runtime.resolvePortableFileReference

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
