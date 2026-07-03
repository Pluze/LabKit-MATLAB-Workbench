% Expected caller: DIC preprocess runner and direct unit tests. Input is an
% applied crop rectangle in image coordinates. Output is the post-crop detail
% text shown by the app. Side effects: none.

function lines = cropSummary(rect)
%CROPSUMMARY Build applied crop detail text.

    lines = { ...
        sprintf('Crop source: current reference and current moving images'), ...
        sprintf('Crop rectangle: x=%g, y=%g, width=%g, height=%g', ...
        rect(1), rect(2), rect(3), rect(4))};
end
