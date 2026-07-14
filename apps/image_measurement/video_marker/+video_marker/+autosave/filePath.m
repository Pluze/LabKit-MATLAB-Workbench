%FILEPATH Build a stable recovery MAT path for one source video path.
% Expected callers are Video Marker autosave helpers and tests. The optional
% root keeps tests isolated from the user's preference directory.
function pathValue = filePath(videoPath, root)
    if nargin < 2 || strlength(string(root)) == 0
        root = video_marker.autosave.rootFolder(videoPath);
    end
    videoPath = string(videoPath);
    [~, base] = fileparts(videoPath);
    base = string(matlab.lang.makeValidName(char(base)));
    if strlength(base) == 0
        base = "video";
    end
    pathValue = fullfile(string(root), base + ".video_marker.autosave.mat");
end
