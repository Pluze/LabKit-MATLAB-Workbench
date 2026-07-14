%READ Load matching Video Marker recovery state when present.
% Expected caller: video-open recovery flow and tests. Returns found=false for
% no file; a mismatched embedded video path is rejected as invalid recovery.
function [state, found] = read(videoPath, root)
    if nargin < 2
        root = "";
    end
    pathValue = video_marker.autosave.filePath(videoPath, root);
    found = exist(pathValue, 'file') == 2;
    state = struct();
    if ~found
        return;
    end
    state = video_marker.projectFiles.loadProject(pathValue);
    if canonicalExistingPath(state.videoPath) ~= canonicalExistingPath(videoPath)
        [~, savedName, savedExtension] = fileparts(string(state.videoPath));
        [~, selectedName, selectedExtension] = fileparts(string(videoPath));
        if ~strcmpi(savedName + savedExtension, selectedName + selectedExtension)
            error('labkit_VideoMarker_app:AutosaveVideoMismatch', ...
                'Recovery data does not match the selected video path.');
        end
        state.videoPath = canonicalExistingPath(videoPath);
        state.videoInfo.path = state.videoPath;
    end
end

function pathValue = canonicalExistingPath(pathValue)
    [exists, attributes] = fileattrib(char(pathValue));
    if exists
        pathValue = string(attributes.Name);
    else
        pathValue = string(pathValue);
    end
end
