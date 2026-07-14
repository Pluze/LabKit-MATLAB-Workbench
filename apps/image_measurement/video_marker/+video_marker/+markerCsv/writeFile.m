%WRITEFILE Write the self-describing marker CSV used for app round trips.
% Expected caller: marker export action and tests. The table stores original
% pixel coordinates for every source frame and can be imported by readFile.
function writeFile(filepath, annotations, skeleton, videoInfo, calibration)
    filepath = string(filepath);
    metadata = struct();
    metadata.schema_version = 1;
    metadata.video = videoInfo;
    metadata.skeleton = skeleton;
    metadata.calibration = calibration;
    metadata.coordinate_origin = "top_left_pixel_center";
    metadata.coordinate_index_base = 1;

    fid = fopen(filepath, 'w');
    if fid < 0
        error('labkit_VideoMarker_app:CsvWriteFailed', 'Could not open marker CSV for writing.');
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '# labkit.video_marker.csv\n');
    fprintf(fid, '# metadata=%s\n', jsonencode(metadata));
    fprintf(fid, '%s\n', strjoin(markerHeader(skeleton), ','));
    frameCount = size(annotations.coords, 1);
    for f = 1:frameCount
        values = strings(1, 3 + 2 * numel(skeleton.pointIds));
        values(1) = string(f);
        values(2) = sprintf('%.15g', (f - 1) / double(videoInfo.frameRate));
        values(3) = video_marker.frameAnnotations.statusName(annotations.frameStatus(f));
        col = 4;
        for p = 1:numel(skeleton.pointIds)
            values(col) = numericCell(annotations.coords(f, p, 1));
            values(col + 1) = numericCell(annotations.coords(f, p, 2));
            col = col + 2;
        end
        fprintf(fid, '%s\n', strjoin(values, ','));
    end
end

function header = markerHeader(skeleton)
    pointCount = numel(skeleton.pointIds);
    header = strings(1, 3 + 2 * pointCount);
    header(1:3) = ["frame_index", "time_s", "frame_status"];
    col = 4;
    for p = 1:numel(skeleton.pointIds)
        base = string(skeleton.pointIds(p));
        header(col) = base + "__x_px";
        header(col + 1) = base + "__y_px";
        col = col + 2;
    end
end

function text = numericCell(value)
    value = double(value);
    if isfinite(value)
        text = string(sprintf('%.15g', value));
    else
        text = "";
    end
end
