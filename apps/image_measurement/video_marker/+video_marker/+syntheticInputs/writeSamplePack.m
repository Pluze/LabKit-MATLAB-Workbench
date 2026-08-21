% App-owned implementation for video_marker.syntheticInputs.writeSamplePack within the video_marker product workflow.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Create a typed synthetic Video Marker reproduction.
% Expected caller: diagnostic startup and focused sample-pack tests. The
% generated video and project contain no user paths, identifiers, or lab data.
arguments
    sampleContext (1, 1) labkit.app.synthetic.Context
end

videoPath = sampleContext.samplePath( ...
    "video_marker/synthetic_video_marker.avi");
writeSyntheticVideo(videoPath);
[~, info] = video_marker.videoSource.openVideo(videoPath);
clear reader

preset = video_marker.skeletonSetup.presets();
project = video_marker.initialData();
project.inputs.sources = sampleContext.sourceRecord( ...
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

markerOutput = sampleContext.outputPath( ...
    "video_marker/video_marker_markers.csv");
coordinateOutput = sampleContext.outputPath( ...
    "video_marker/video_marker_coordinates.csv");
pack = labkit.app.synthetic.Pack( ...
    Scenario="representative-video-marking", ...
    InitialInput=project, ...
    Artifacts={ ...
        sampleContext.artifact("video", "video", videoPath), ...
        sampleContext.artifact("markerCsv", "markerCsv", ...
            markerOutput, Expectation="exports"), ...
        sampleContext.artifact("coordinateCsv", "coordinateCsv", ...
            coordinateOutput, Expectation="exports")});
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
