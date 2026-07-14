%DISCARD Delete recovery state for one source video when present.
% Expected caller: explicit new-session and decline-recovery paths.
function discard(videoPath, root)
    if nargin < 2
        root = "";
    end
    pathValue = video_marker.autosave.filePath(videoPath, root);
    if exist(pathValue, 'file') == 2
        delete(pathValue);
    end
end
