%FILEPATH Return the stable visible autosave path for one source video.
% Expected caller: Video Marker save-autosave action. Input is a nonempty
% source video path. Output is beside the video under Video Marker Autosaves;
% no dialog is opened and no file is written by this function.
function filepath = filePath(videoPath)
    videoPath = string(videoPath);
    if ~isscalar(videoPath) || strlength(videoPath) == 0
        error('video_marker:AutosaveSourceMissing', ...
            'Video Marker autosave requires a source video path.');
    end
    [folder, base, ~] = fileparts(videoPath);
    if strlength(string(folder)) == 0 || strlength(string(base)) == 0
        error('video_marker:AutosaveSourceMissing', ...
            'Video Marker autosave requires a source video with a parent folder.');
    end
    safeBase = string(matlab.lang.makeValidName(char(base)));
    filepath = string(fullfile(folder, "Video Marker Autosaves", ...
        safeBase + ".video_marker.autosave.mat"));
end
