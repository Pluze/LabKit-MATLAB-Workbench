function project = project(rootFolder)
%PROJECT Create a Video Marker input used by several behavior specs.
arguments
    rootFolder (1, 1) string
end

sampleFolder = string(fullfile(rootFolder, "video_marker"));
if exist(sampleFolder, "dir") ~= 7
    mkdir(sampleFolder);
end
videoPath = string(fullfile(sampleFolder, "video.avi"));
writeSyntheticVideo(videoPath);
[~, info] = video_marker.videoSource.openVideo(videoPath);
clear reader

preset = video_marker.skeletonSetup.presets();
project = video_marker.initialData();
project.inputs.sources = labkit.app.source.record( ...
    "video", "video", videoPath);
project.inputs.videoMetadata = ...
    video_marker.videoSource.metadataFromInfo(info);
project.annotations.skeleton = ...
    video_marker.skeletonDefinition.fromParts( ...
        preset(1).pointNames, preset(1).edges);
project.annotations.frames = ...
    video_marker.frameAnnotations.emptyAnnotations( ...
        info.frameCount, numel(preset(1).pointNames));
project.parameters.coordinateEndFrame = info.frameCount;
end

function writeSyntheticVideo(videoPath)
writer = VideoWriter(char(videoPath), "Motion JPEG AVI");
writer.FrameRate = 10;
open(writer);
cleanup = onCleanup(@() close(writer));
for k = 1:6
    frame = uint8(zeros(72, 96, 3));
    x = 16 + 8 * k;
    y = 42 + round(8 * sin(k / 2));
    frame(:, :, 1) = uint8(30 + 4 * k);
    frame(:, :, 2) = uint8(40);
    frame(max(1, y-2):min(72, y+2), ...
        max(1, x-2):min(96, x+2), :) = 240;
    writeVideo(writer, frame);
end
clear cleanup
end
