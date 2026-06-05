% App-private image measurement helper. Expected caller: owning app callbacks
% and temporary compatibility tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function T = buildFocusStackSummaryTable(result, paths)
%BUILDFOCUSSTACKSUMMARYTABLE Build summary CSV table for labkit_FocusStack_app.
%
% Expected caller:
%   labkit_FocusStack_app export callback and temporary compatibility test handlers.
%
% Inputs/outputs:
%   Completed focus-stack result and source image paths. Returns the app-owned
%   summary table with stable column order and display names.
%
% Side effects:
%   None. The caller owns file writing.

    if ~result.ok
        error('labkit_FocusStack_app:NoResult', ...
            'A completed focus-stack result is required to build a summary table.');
    end
    paths = string(paths(:));
    if numel(paths) ~= result.inputCount
        paths = defaultSliceNames(result.inputCount);
    end

    imageNames = strings(result.inputCount, 1);
    for k = 1:result.inputCount
        imageNames(k) = string(displayNameFromPath(paths(k)));
    end

    T = table( ...
        imageNames, ...
        (1:result.inputCount).', ...
        result.focusCoverage(:), ...
        100 .* result.focusCoverage(:), ...
        repmat(result.meanConfidence, result.inputCount, 1), ...
        repmat(string(result.method), result.inputCount, 1), ...
        repmat(result.imageHeight, result.inputCount, 1), ...
        repmat(result.imageWidth, result.inputCount, 1), ...
        repmat(result.focusWindow, result.inputCount, 1), ...
        repmat(result.smoothRadius, result.inputCount, 1), ...
        repmat(result.minConfidence, result.inputCount, 1), ...
        'VariableNames', {'SourceImage', 'FocusIndex', ...
        'SelectedPixelFraction', 'SelectedPixelPercent', 'MeanConfidence', ...
        'Method', 'FusedHeight_px', 'FusedWidth_px', ...
        'DetailScale_px', 'BlendRadius_px', 'UncertainBlendFraction'});
end

function names = defaultSliceNames(imageCount)
    names = strings(imageCount, 1);
    for k = 1:imageCount
        names(k) = sprintf('slice_%03d', k);
    end
end
