%ROOTFOLDER Return the visible recovery subfolder beside a source video.
% Expected callers are app-owned autosave helpers. An environment override is
% supported only for isolated tests; production keeps recovery with the video.
function folder = rootFolder(videoPath)
    folder = string(getenv('LABKIT_VIDEO_MARKER_AUTOSAVE_ROOT'));
    if strlength(folder) == 0
        [videoFolder, ~, ~] = fileparts(string(videoPath));
        if strlength(videoFolder) == 0
            error('labkit_VideoMarker_app:AutosaveVideoFolderMissing', ...
                'Autosave requires a video path with a parent folder.');
        end
        folder = fullfile(videoFolder, "Video Marker Autosaves");
    end
end
