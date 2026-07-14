%OPENVIDEO Read indexed metadata for one video file.
% Expected caller: labkit_VideoMarker_app open-video action. Inputs are a
% path scalar. Outputs are VideoReader handle and serializable metadata.
function [reader, info] = openVideo(videoPath)
    videoPath = string(videoPath);
    if strlength(videoPath) == 0 || exist(videoPath, 'file') ~= 2
        error('labkit_VideoMarker_app:VideoNotFound', 'Video file was not found.');
    end

    reader = VideoReader(char(videoPath));
    frameRate = double(reader.FrameRate);
    duration = double(reader.Duration);
    try
        frameCount = double(reader.NumFrames);
    catch
        % Constant: small tolerance absorbs floating-point duration/frameRate
        % products that land just below an integer frame count.
        frameCountTolerance = 1e-9;
        frameCount = max(1, floor(duration * frameRate + frameCountTolerance));
    end
    info = struct( ...
        "path", videoPath, ...
        "frameCount", frameCount, ...
        "frameRate", frameRate, ...
        "duration", duration, ...
        "height", double(reader.Height), ...
        "width", double(reader.Width));
end
