%WRITE Atomically save recovery state for one source video.
% Expected caller: Video Marker action callbacks after durable state changes.
% The optional root is for isolated tests. No current frame image is stored.
function pathValue = write(videoPath, state, root)
    if nargin < 3
        root = "";
    end
    pathValue = video_marker.autosave.filePath(videoPath, root);
    folder = fileparts(pathValue);
    if exist(folder, 'dir') ~= 7
        mkdir(folder);
    end
    tempPath = pathValue + ".tmp";
    cleanupObj = onCleanup(@() deleteIfPresent(tempPath));
    video_marker.projectFiles.saveProject(tempPath, state);
    [ok, message] = movefile(tempPath, pathValue, 'f');
    if ~ok
        error('labkit_VideoMarker_app:AutosaveMoveFailed', '%s', message);
    end
    clear cleanupObj;
end

function deleteIfPresent(pathValue)
    if exist(pathValue, 'file') == 2
        delete(pathValue);
    end
end
