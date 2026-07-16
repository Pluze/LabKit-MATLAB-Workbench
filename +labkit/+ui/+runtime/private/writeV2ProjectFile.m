% Private UI runtime helper. Expected callers: explicit save and recovery
% policy. Inputs are a target MAT path and validated project envelope. Side
% effect writes a temporary file, reads it back, then atomically replaces the
% target while preserving any prior file if validation or replacement fails.
function writeV2ProjectFile(filepath, labkitProject, beforeReplace)
    if nargin < 3
        beforeReplace = [];
    end
    filepath = string(filepath);
    folder = string(fileparts(filepath));
    if strlength(folder) == 0
        folder = string(pwd);
        filepath = fullfile(folder, filepath);
    end
    if ~isfolder(folder)
        error('labkit:ui:runtime:ProjectWriteFailed', ...
            'Project destination folder does not exist: %s.', folder);
    end
    temporary = string(tempname(folder)) + ".mat";
    cleanup = onCleanup(@() deleteIfPresent(temporary));
    save(temporary, 'labkitProject');
    inventory = whos('-file', temporary);
    if numel(inventory) ~= 1 || string(inventory.name) ~= "labkitProject"
        error('labkit:ui:runtime:ProjectWriteFailed', ...
            'Temporary project readback inventory was invalid.');
    end
    readback = load(temporary, 'labkitProject');
    if ~isequaln(readback.labkitProject, labkitProject)
        error('labkit:ui:runtime:ProjectWriteFailed', ...
            'Temporary project readback did not match the encoded document.');
    end
    if isa(beforeReplace, 'function_handle')
        beforeReplace(temporary, filepath);
    end
    [moved, message] = movefile(temporary, filepath, 'f');
    if ~moved
        error('labkit:ui:runtime:ProjectWriteFailed', ...
            'Could not replace project file: %s.', message);
    end
    clear cleanup;
end

function deleteIfPresent(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end
