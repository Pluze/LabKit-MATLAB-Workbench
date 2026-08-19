function summary = writeAnnotatedVideo(videoPath, outputPath, annotations, skeleton, progressFcn)
%WRITEANNOTATEDVIDEO Render a complete video with landmark overlays.
% Syntax:
%   summary = video_marker.resultFiles.writeAnnotatedVideo( ...
%       videoPath, outputPath, annotations, skeleton)
%   summary = video_marker.resultFiles.writeAnnotatedVideo( ...
%       videoPath, outputPath, annotations, skeleton, progressFcn)
%
% Inputs:
%   videoPath - Existing scalar path to a video readable by VideoReader.
%   outputPath - Scalar destination ending in .mp4. The output uses MPEG-4
%       with H.264 encoding. An existing destination is
%       replaced only after the complete temporary render succeeds.
%   annotations - Video Marker frame-annotation scalar struct. Coordinates
%       are pixel-center x/y positions in source-frame coordinates. Missing
%       or incomplete frames remain valid and receive only their finite
%       ordered point prefix.
%   skeleton - Video Marker skeleton scalar struct containing pointIds,
%       pointNames, and one-based edge endpoint indices.
%   progressFcn - Optional function handle called as
%       progressFcn(stage,completed,total) at start, completion, and at least
%       every 30 seconds while frames remain. Default: no callback.
%
% Outputs:
%   summary - Scalar struct containing frameCount, frameRate, width, and
%       height for the written video.
%
% Description:
%   Every source frame is retained. Finite landmark points are burned in as
%   cyan circles and skeleton edges are burned in as blue lines. Empty frames
%   are written unchanged. The output keeps the source frame rate and pixel
%   dimensions when both are even. MATLAB pads an odd width or height by one
%   pixel for MPEG-4. Rendering uses Base MATLAB pixel operations and does
%   not require a graphics window or an optional image/video toolbox.
%
% Errors:
%   video_marker:InvalidVideoRenderInput - Paths, annotations, skeleton, or
%       the progress callback are malformed.
%   video_marker:UnsupportedVideoOutput - The output extension is not MP4.
%   video_marker:Mpeg4Unavailable - MATLAB MPEG-4 writing is unavailable on
%       the current platform. VideoReader and VideoWriter errors are
%       otherwise passed through unchanged.
%
% Typical Call:
%   summary = video_marker.resultFiles.writeAnnotatedVideo( ...
%       "source.avi", "annotated.mp4", annotations, skeleton);
%
% See also VideoReader, VideoWriter, video_marker.frameAnnotations.framePoints

if nargin < 5
    progressFcn = [];
end
[videoPath, outputPath] = validateInputs( ...
    videoPath, outputPath, annotations, skeleton, progressFcn);
[reader, info] = video_marker.videoSource.openVideo(videoPath);
[profile, extension] = outputProfile(outputPath);
[outputFolder, ~, ~] = fileparts(outputPath);
if strlength(outputFolder) == 0
    outputFolder = string(pwd);
end
if ~isfolder(outputFolder)
    error("video_marker:InvalidVideoRenderInput", ...
        "The annotated-video output folder does not exist.");
end
temporaryPath = string(tempname(outputFolder)) + extension;
temporaryCleanup = onCleanup(@() deleteIfPresent(temporaryPath));
writer = VideoWriter(char(temporaryPath), profile);
writer.FrameRate = info.frameRate;
open(writer);
writerCleanup = onCleanup(@() close(writer));

expectedCount = max(1, info.frameCount);
report(progressFcn, "started", 0, expectedCount);
lastReport = tic;
frameIndex = 0;
while hasFrame(reader)
    frameIndex = frameIndex + 1;
    frame = readFrame(reader);
    points = pointsForFrame(annotations, frameIndex);
    frame = burnOverlay(frame, points, skeleton.edges);
    writeVideo(writer, frame);
    if toc(lastReport) >= 30 || frameIndex == expectedCount
        report(progressFcn, "rendering", frameIndex, expectedCount);
        lastReport = tic;
    end
end
clear writerCleanup
if frameIndex == 0
    error("video_marker:InvalidVideoRenderInput", ...
        "The source video contains no readable frames.");
end
movefile(temporaryPath, outputPath, "f");
clear temporaryCleanup
report(progressFcn, "completed", frameIndex, frameIndex);
summary = struct("frameCount", frameIndex, ...
    "frameRate", info.frameRate, "width", ...
    info.width + mod(info.width, 2), ...
    "height", info.height + mod(info.height, 2));
end

function [videoPath, outputPath] = validateInputs( ...
        videoPath, outputPath, annotations, skeleton, progressFcn)
videoPath = string(videoPath);
outputPath = string(outputPath);
if ~isscalar(videoPath) || strlength(videoPath) == 0 || ...
        ~isscalar(outputPath) || strlength(outputPath) == 0
    error("video_marker:InvalidVideoRenderInput", ...
        "Annotated-video input and output paths must be nonempty scalar text.");
end
if ~isstruct(annotations) || ~isscalar(annotations) || ...
        ~isfield(annotations, "coords") || ...
        ~isnumeric(annotations.coords) || ...
        ndims(annotations.coords) ~= 3 || size(annotations.coords, 3) ~= 2
    error("video_marker:InvalidVideoRenderInput", ...
        "Annotated-video frame annotations must contain a numeric frame-by-point-by-2 coords array.");
end
if ~isstruct(skeleton) || ~isscalar(skeleton) || ...
        ~all(isfield(skeleton, {'pointIds', 'pointNames', 'edges'})) || ...
        ~isnumeric(skeleton.edges) || size(skeleton.edges, 2) ~= 2
    error("video_marker:InvalidVideoRenderInput", ...
        "Annotated-video skeleton must contain point identifiers, names, and a two-column edge array.");
end
if size(annotations.coords, 2) ~= numel(skeleton.pointIds)
    error("video_marker:InvalidVideoRenderInput", ...
        "Annotated-video coordinates must match the skeleton point count.");
end
if any(skeleton.edges(:) < 1) || ...
        any(skeleton.edges(:) > numel(skeleton.pointIds)) || ...
        any(skeleton.edges(:) ~= fix(skeleton.edges(:)))
    error("video_marker:InvalidVideoRenderInput", ...
        "Annotated-video skeleton edges must contain valid one-based point indices.");
end
if ~isempty(progressFcn) && ...
        (~isa(progressFcn, "function_handle") || ~isscalar(progressFcn))
    error("video_marker:InvalidVideoRenderInput", ...
        "Annotated-video progress callback must be empty or a scalar function handle.");
end
end

function [profile, extension] = outputProfile(outputPath)
[~, ~, extension] = fileparts(outputPath);
extension = lower(string(extension));
if extension ~= ".mp4"
    error("video_marker:UnsupportedVideoOutput", ...
        "Annotated video output must end in .mp4.");
end
if ~(ismac || ispc)
    error("video_marker:Mpeg4Unavailable", ...
        "MATLAB MPEG-4 video writing is available only on macOS and Windows.");
end
profile = "MPEG-4";
end

function points = pointsForFrame(annotations, frameIndex)
if frameIndex > size(annotations.coords, 1)
    points = zeros(0, 2);
else
    points = video_marker.frameAnnotations.framePoints( ...
        annotations, frameIndex);
end
end

function frame = burnOverlay(frame, points, edges)
frame = rgbUint8(frame);
if isempty(points)
    return
end
imageScale = min(size(frame, 1), size(frame, 2));
lineRadius = max(1, round(imageScale / 360));
pointRadius = max(3, round(imageScale / 120));
lineColor = uint8([26 166 255]);
pointColor = uint8([0 217 255]);
for k = 1:size(edges, 1)
    edge = edges(k, :);
    if all(edge <= size(points, 1))
        frame = paintLine(frame, points(edge(1), :), ...
            points(edge(2), :), lineRadius, lineColor);
    end
end
for k = 1:size(points, 1)
    frame = paintDisk(frame, points(k, :), pointRadius, pointColor);
end
end

function frame = rgbUint8(frame)
if ismatrix(frame)
    frame = repmat(frame, 1, 1, 3);
elseif size(frame, 3) > 3
    frame = frame(:, :, 1:3);
end
if isa(frame, "uint8")
    return
end
if isinteger(frame)
    frame = uint8(round(double(frame) * 255 / double(intmax(class(frame)))));
else
    frame = double(frame);
    if ~isempty(frame) && max(frame, [], "all") <= 1 && ...
            min(frame, [], "all") >= 0
        frame = frame * 255;
    end
    frame = uint8(min(max(round(frame), 0), 255));
end
end

function frame = paintLine(frame, firstPoint, secondPoint, radius, color)
stepCount = max(1, ceil(max(abs(secondPoint - firstPoint))));
x = linspace(firstPoint(1), secondPoint(1), stepCount + 1);
y = linspace(firstPoint(2), secondPoint(2), stepCount + 1);
for k = 1:numel(x)
    frame = paintDisk(frame, [x(k) y(k)], radius, color);
end
end

function frame = paintDisk(frame, point, radius, color)
centerX = round(point(1));
centerY = round(point(2));
xRange = max(1, centerX-radius):min(size(frame, 2), centerX+radius);
yRange = max(1, centerY-radius):min(size(frame, 1), centerY+radius);
if isempty(xRange) || isempty(yRange)
    return
end
[xGrid, yGrid] = meshgrid(xRange, yRange);
mask = (xGrid - point(1)).^2 + (yGrid - point(2)).^2 <= radius^2;
for channel = 1:3
    plane = frame(yRange, xRange, channel);
    plane(mask) = color(channel);
    frame(yRange, xRange, channel) = plane;
end
end

function report(progressFcn, stage, completed, total)
if ~isempty(progressFcn)
    progressFcn(string(stage), double(completed), double(total));
end
end

function deleteIfPresent(path)
if isfile(path)
    delete(path);
end
end
