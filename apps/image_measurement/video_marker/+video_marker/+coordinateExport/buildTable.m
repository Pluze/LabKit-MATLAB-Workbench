function T = buildTable(annotations, skeleton, videoInfo, calibration, opts)
%BUILDTABLE Convert confirmed video annotations to a coordinate table.
%
% Usage:
%   T = video_marker.coordinateExport.buildTable( ...
%       annotations, skeleton, videoInfo, calibration, opts)
%
% Description:
%   Exports a continuous range of confirmed frames in a rectangular table
%   suitable for CSV files or direct MATLAB analysis. Coordinates can remain in
%   pixels or be converted with the project's physical scale. The origin and
%   vertical-axis direction are applied consistently to every keypoint while
%   the stored annotation arrays remain unchanged.
%
% Inputs:
%   annotations - Frame annotation structure. annotations.coords must be an
%       F-by-P-by-2 array in [x y] pixel coordinates, and frameStatus must mark
%       every exported frame as "confirmed".
%   skeleton - Skeleton structure with P ordered pointIds. Each point ID is
%       converted with matlab.lang.makeValidName for table variable names.
%   videoInfo - Scalar structure with frameRate in frames per second. time_s is
%       calculated as (frame_index-1)/frameRate.
%   calibration - Scale structure with pixelsPerUnit and unit. It is required
%       only when opts.unitMode is "calibrated_physical".
%   opts - Coordinate export structure, normally created by
%       video_marker.coordinateExport.options.
%
% Options:
%   startFrame - First exported one-based frame index. It is rounded and
%       limited to at least one. Default from options: 1.
%   endFrame - Last exported frame index, inclusive. It is rounded and limited
%       to the annotation frame count. Default from options: Inf.
%   unitMode - "pixels" retains pixel distances and reports "px";
%       "calibrated_physical" divides distances by calibration.pixelsPerUnit
%       and reports calibration.unit. Default: "pixels".
%   originMode - "top_left_pixel_center" subtracts [1 1], so the center of the
%       upper-left pixel is [0 0]. "first_point" subtracts the first skeleton
%       point's coordinates at startFrame from all frames. Default:
%       "top_left_pixel_center".
%   yAxisMode - "down" preserves image-row direction; "up" negates vertical
%       displacement so positive y points upward. Default: "up".
%
% Outputs:
%   T - Table with one row per exported frame. Fixed variables are frame_index,
%       time_s, coordinate_unit, y_axis, origin_mode, origin_frame_index,
%       origin_point_id, and pixels_per_unit. Every skeleton point adds
%       <pointId>__x and <pointId>__y numeric variables in skeleton order.
%
% Errors:
%   labkit_VideoMarker_app:InvalidFrameRange - The limited end frame precedes
%       the limited start frame.
%   labkit_VideoMarker_app:UnconfirmedFrameRange - Any selected frame is not
%       confirmed.
%   labkit_VideoMarker_app:MissingScaleCalibration - Physical units are
%       requested without a positive finite pixelsPerUnit value.
%   labkit_VideoMarker_app:InvalidOriginMode - originMode is unsupported.
%   labkit_VideoMarker_app:InvalidYAxisMode - yAxisMode is unsupported.
%
% Example:
%   skeleton = video_marker.skeletonDefinition.fromText("hip, knee", "hip-knee");
%   annotations = video_marker.frameAnnotations.emptyAnnotations(2, 2);
%   annotations = video_marker.frameAnnotations.setFramePoints( ...
%       annotations, 1, [11 21; 31 41], "confirmed");
%   annotations = video_marker.frameAnnotations.setFramePoints( ...
%       annotations, 2, [13 25; 35 45], "confirmed");
%   info = struct("frameRate", 10);
%   opts = video_marker.coordinateExport.options( ...
%       "startFrame", 1, "endFrame", 2, "unitMode", "pixels", ...
%       "originMode", "first_point", "yAxisMode", "up");
%   T = video_marker.coordinateExport.buildTable( ...
%       annotations, skeleton, info, struct(), opts);
%   assert(isequal(T.hip__x, [0; 2]) && isequal(T.hip__y, [0; -4]))
%
% See also video_marker.coordinateExport.options,
%   video_marker.frameAnnotations.emptyAnnotations,
%   video_marker.skeletonDefinition.fromText

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
