% App-owned geometry helper. Expected caller: batch-crop preview and center
% callbacks. Input is an image array. Output is the one-based center
% coordinate [x y] in source-image coordinates.
function centerXY = sourceCenterXY(imageData)
%SOURCECENTERXY Return the one-based geometric center of an image.

    centerXY = batch_crop.cropGeometry.sourceCenterFromSize(size(imageData, 2), size(imageData, 1));
end
