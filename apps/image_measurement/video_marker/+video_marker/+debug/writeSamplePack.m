%WRITESAMPLEPACK Create synthetic debug assets for labkit_VideoMarker_app.
% Expected caller: debug launch and debug sample-pack tests. Outputs contain
% generated local files only; no lab sample data is copied.
function pack = writeSamplePack(debugLog)
    sampleFolder = string(debugLog.sampleFolder());
    outputFolder = string(debugLog.outputFolder());
    if exist(sampleFolder, 'dir') ~= 7
        mkdir(sampleFolder);
    end
    if exist(outputFolder, 'dir') ~= 7
        mkdir(outputFolder);
    end

    videoPath = fullfile(sampleFolder, "synthetic_video_marker.avi");
    writeSyntheticVideo(videoPath);

    pack = struct();
    pack.sampleFolder = sampleFolder;
    pack.outputFolder = outputFolder;
    pack.representativeFiles = videoPath;
    pack.boundaryFiles = struct();
    pack.boundaryFiles.project = fullfile(sampleFolder, "empty_video_marker_project.mat");
    pack.boundaryFiles.markerCsv = fullfile(sampleFolder, "empty_video_marker_markers.csv");
end

function writeSyntheticVideo(videoPath)
    writer = VideoWriter(char(videoPath), 'Motion JPEG AVI');
    writer.FrameRate = 10;
    open(writer);
    cleanup = onCleanup(@() close(writer));
    for k = 1:6
        frame = uint8(zeros(72, 96, 3));
        x = 16 + 8 * k;
        y = 42 + round(8 * sin(k / 2));
        frame(:, :, 1) = uint8(30 + 4 * k);
        frame(:, :, 2) = uint8(40);
        frame(max(1, y-2):min(72, y+2), max(1, x-2):min(96, x+2), :) = 240;
        writeVideo(writer, frame);
    end
end
