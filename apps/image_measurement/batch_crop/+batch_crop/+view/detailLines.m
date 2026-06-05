% App-owned detail view helper. Expected caller: batch-crop app refreshSummary.
% Inputs are app state, current index, crop size, and fill mode. Output is a
% cell vector of text lines and has no side effects.
function lines = detailLines(state, currentIndex, cropWidth, cropHeight, fillMode)
%DETAILLINES Build detail text for the selected crop item.

    if isempty(state.items) || currentIndex < 1 || currentIndex > numel(state.items)
        lines = {'No images loaded.'};
        return;
    end

    item = state.items(currentIndex);
    stateText = ternary(item.centerSet, 'confirmed', 'needs confirmation');
    lines = { ...
        sprintf('Image %d of %d: %s', currentIndex, numel(state.items), ...
        batch_crop.view.displayNameFromPath(item.path)), ...
        sprintf('Crop center: x %.1f, y %.1f (%s)', ...
        item.centerXY(1), item.centerXY(2), stateText), ...
        sprintf('Output size: %d x %d px; rotation: %.3g deg; fill: %s', ...
        cropWidth, cropHeight, item.angleDeg, char(fillMode))};
    if ~isempty(state.lastExport)
        lines{end+1} = sprintf('Last manifest: %s', char(state.lastExport.manifestPath));
    end
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
