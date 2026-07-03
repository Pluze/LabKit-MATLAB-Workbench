% App-owned crop-control helper. Expected caller: batch-crop GUI control
% refresh. Input is image data. Output is the pixel crop upper limit, defined
% as twice the source-image diagonal.
function limit = cropSizeUpperLimit(imageData)
    limit = max(1, ceil(2 * hypot(double(size(imageData, 2)), ...
        double(size(imageData, 1)))));
end
