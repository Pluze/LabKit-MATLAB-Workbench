%READFILE Import a marker CSV written by video_marker.markerCsv.writeFile.
% Expected caller: marker import action and tests. Import validates the full
% file before returning replacement annotations and metadata.
function payload = readFile(filepath)
    filepath = string(filepath);
    lines = readlines(filepath);
    lines = lines(strlength(lines) > 0);
    if isempty(lines) || strtrim(lines(1)) ~= "# labkit.video_marker.csv"
        error('labkit_VideoMarker_app:InvalidMarkerCsv', 'Marker CSV header is missing.');
    end
    metadataLine = lines(startsWith(strtrim(lines), "# metadata="));
    if isempty(metadataLine)
        error('labkit_VideoMarker_app:InvalidMarkerCsv', 'Marker CSV metadata is missing.');
    end
    metadataText = extractAfter(strtrim(metadataLine(1)), "# metadata=");
    metadata = jsondecode(char(metadataText));
    skeleton = normalizeSkeleton(metadata.skeleton);
    videoInfo = normalizeVideoInfo(metadata.video);
    calibration = metadata.calibration;

    T = readtable(filepath, "FileType", "text", "CommentStyle", "#", ...
        "TextType", "string", "VariableNamingRule", "preserve");
    required = markerHeader(skeleton);
    missing = setdiff(required, string(T.Properties.VariableNames), "stable");
    if ~isempty(missing)
        error('labkit_VideoMarker_app:InvalidMarkerCsv', ...
            'Marker CSV is missing expected coordinate columns.');
    end

    frameCount = height(T);
    pointCount = numel(skeleton.pointIds);
    annotations = video_marker.frameAnnotations.emptyAnnotations(frameCount, pointCount);
    for f = 1:frameCount
        if T.frame_index(f) ~= f
            error('labkit_VideoMarker_app:InvalidMarkerCsv', ...
                'Frame indices must be contiguous and 1-based.');
        end
        status = string(T.frame_status(f));
        points = zeros(0, 2);
        for p = 1:pointCount
            x = T.(char(skeleton.pointIds(p) + "__x_px"))(f);
            y = T.(char(skeleton.pointIds(p) + "__y_px"))(f);
            if isfinite(x) && isfinite(y)
                points(end+1, :) = [x y]; %#ok<AGROW>
            elseif isfinite(x) || isfinite(y)
                error('labkit_VideoMarker_app:InvalidMarkerCsv', ...
                    'Point coordinate pairs must be both finite or both blank.');
            else
                later = anyFiniteLater(T, skeleton, f, p + 1);
                if later
                    error('labkit_VideoMarker_app:InvalidMarkerCsv', ...
                        'Draft marker coordinates must be an ordered prefix.');
                end
                break;
            end
        end
        annotations = video_marker.frameAnnotations.setFramePoints(annotations, f, points, status);
    end

    payload = struct();
    payload.annotations = annotations;
    payload.skeleton = skeleton;
    payload.videoInfo = videoInfo;
    payload.calibration = calibration;
end

function skeleton = normalizeSkeleton(raw)
    skeleton = struct();
    skeleton.schemaVersion = double(raw.schemaVersion);
    skeleton.pointIds = string(raw.pointIds(:));
    skeleton.pointNames = string(raw.pointNames(:));
    skeleton.edges = double(raw.edges);
end

function info = normalizeVideoInfo(raw)
    info = struct( ...
        "path", string(raw.path), ...
        "frameCount", double(raw.frameCount), ...
        "frameRate", double(raw.frameRate), ...
        "duration", double(raw.duration), ...
        "height", double(raw.height), ...
        "width", double(raw.width));
end

function header = markerHeader(skeleton)
    header = ["frame_index", "time_s", "frame_status"];
    for p = 1:numel(skeleton.pointIds)
        base = string(skeleton.pointIds(p));
        header(end+1) = base + "__x_px"; %#ok<AGROW>
        header(end+1) = base + "__y_px"; %#ok<AGROW>
    end
end

function tf = anyFiniteLater(T, skeleton, frameIndex, startPoint)
    tf = false;
    for p = startPoint:numel(skeleton.pointIds)
        x = T.(char(skeleton.pointIds(p) + "__x_px"))(frameIndex);
        y = T.(char(skeleton.pointIds(p) + "__y_px"))(frameIndex);
        tf = tf || isfinite(x) || isfinite(y);
    end
end
