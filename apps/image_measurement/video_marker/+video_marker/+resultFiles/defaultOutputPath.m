% App-owned implementation for video_marker.resultFiles.defaultOutputPath within the video_marker product workflow.
function filepath = defaultOutputPath(videoPath, filename)
%DEFAULTOUTPUTPATH Return the source-adjacent Video Marker export path.
% Expected callers are the marker and coordinate export callbacks. Inputs
% are the resolved source video path and one fixed App-owned output filename.
videoPath = string(videoPath);
filename = string(filename);
if ~isscalar(videoPath) || ~isscalar(filename) || strlength(filename) == 0
    error("video_marker:InvalidOutputPath", ...
        "Video Marker export paths require scalar source and file names.");
end
[sourceFolder, ~, ~] = fileparts(videoPath);
if strlength(sourceFolder) == 0 || ~isfolder(sourceFolder)
    sourceFolder = string(pwd);
end
folder = fullfile(sourceFolder, "video_marker");
if ~isfolder(folder)
    try
        mkdir(folder);
    catch
    end
end
if ~isfolder(folder)
    folder = sourceFolder;
end
filepath = string(fullfile(folder, filename));
end
