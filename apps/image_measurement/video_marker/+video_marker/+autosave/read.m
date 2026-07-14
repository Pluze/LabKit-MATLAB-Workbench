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
    if string(state.videoPath) ~= string(videoPath)
        error('labkit_VideoMarker_app:AutosaveVideoMismatch', ...
            'Recovery data does not match the selected video path.');
    end
end
