% App-owned geometry helper. Expected caller: batch-crop coordinate and
% preview helpers. Input is a crop geometry struct. Output is the positive
% original-to-preview coordinate scale, defaulting to 1 for full-size geometry.
function scale = geometryScale(geometry)
    scale = 1;
    if isfield(geometry, 'coordinateScale') && ...
            isfinite(double(geometry.coordinateScale)) && ...
            double(geometry.coordinateScale) > 0
        scale = double(geometry.coordinateScale);
    end
end
