%BUILDTABLE Build the plain coordinate CSV table for external plotting.
% Expected caller: coordinate export action and tests. This helper does not
% mutate marker annotations.
function T = buildTable(annotations, skeleton, videoInfo, calibration, opts)
    frameCount = size(annotations.coords, 1);
    pointCount = numel(skeleton.pointIds);
    startFrame = max(1, round(double(opts.startFrame)));
    endFrame = min(frameCount, round(double(opts.endFrame)));
    if endFrame < startFrame
        error('labkit_VideoMarker_app:InvalidFrameRange', 'Export frame range is empty.');
    end
    confirmed = video_marker.frameAnnotations.statusCode("confirmed");
    frameRange = (startFrame:endFrame).';
    if any(annotations.frameStatus(frameRange) ~= confirmed)
        error('labkit_VideoMarker_app:UnconfirmedFrameRange', ...
            'Coordinate CSV export requires a continuous confirmed frame range.');
    end

    [scale, unitName] = coordinateScale(calibration, opts.unitMode);
    [x0, y0, originPointId] = coordinateOrigin(annotations, skeleton, startFrame, opts.originMode);
    yDirection = yAxisDirection(opts.yAxisMode);

    T = table();
    T.frame_index = frameRange;
    T.time_s = (frameRange - 1) ./ double(videoInfo.frameRate);
    T.coordinate_unit = repmat(unitName, numel(frameRange), 1);
    T.y_axis = repmat(string(opts.yAxisMode), numel(frameRange), 1);
    T.origin_mode = repmat(string(opts.originMode), numel(frameRange), 1);
    T.origin_frame_index = repmat(startFrame, numel(frameRange), 1);
    T.origin_point_id = repmat(originPointId, numel(frameRange), 1);
    T.pixels_per_unit = repmat(calibrationPixelsPerUnit(calibration), numel(frameRange), 1);

    for p = 1:pointCount
        x = annotations.coords(frameRange, p, 1);
        y = annotations.coords(frameRange, p, 2);
        base = matlab.lang.makeValidName(char(skeleton.pointIds(p)));
        T.([base '__x']) = (x(:) - x0) .* scale;
        T.([base '__y']) = (y(:) - y0) .* scale .* yDirection;
    end
end

function [scale, unitName] = coordinateScale(calibration, unitMode)
    unitMode = string(unitMode);
    if unitMode == "pixels"
        scale = 1;
        unitName = "px";
        return;
    end
    ppu = calibrationPixelsPerUnit(calibration);
    if ~isfinite(ppu) || ppu <= 0
        error('labkit_VideoMarker_app:MissingScaleCalibration', ...
            'Physical coordinate export requires a valid scale calibration.');
    end
    scale = 1 / ppu;
    unitName = string(calibration.unit);
end

function [x0, y0, pointId] = coordinateOrigin(annotations, skeleton, frameIndex, originMode)
    originMode = string(originMode);
    if originMode == "top_left_pixel_center"
        x0 = 1;
        y0 = 1;
        pointId = "";
        return;
    end
    if originMode ~= "first_point"
        error('labkit_VideoMarker_app:InvalidOriginMode', 'Unknown coordinate origin mode.');
    end
    x0 = annotations.coords(frameIndex, 1, 1);
    y0 = annotations.coords(frameIndex, 1, 2);
    pointId = string(skeleton.pointIds(1));
end

function direction = yAxisDirection(yAxisMode)
    yAxisMode = string(yAxisMode);
    if yAxisMode == "down"
        direction = 1;
    elseif yAxisMode == "up"
        direction = -1;
    else
        error('labkit_VideoMarker_app:InvalidYAxisMode', 'Unknown Y-axis mode.');
    end
end

function ppu = calibrationPixelsPerUnit(calibration)
    ppu = NaN;
    if isstruct(calibration) && isfield(calibration, 'pixelsPerUnit')
        ppu = double(calibration.pixelsPerUnit);
    end
end
