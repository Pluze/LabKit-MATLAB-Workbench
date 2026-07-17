% App-owned detail view helper. Expected caller: batch-crop app refreshSummary.
% Inputs are app state, current index, crop size, and padding percent. Output
% is a cell vector of text lines and has no side effects.
function lines = detailLines(state, currentIndex, cropWidth, cropHeight, paddingPercent)
%DETAILLINES Build detail text for the selected crop item.

    items = state.project.inputs.items;
    if isempty(items) || currentIndex < 1 || currentIndex > numel(items)
        lines = {'No images loaded.'};
        return;
    end

    item = batch_crop.sourceFiles.workingItems( ...
        items(currentIndex), state.session.cache.images(currentIndex), ...
        state.project.inputs.sources);
    stateText = ternary(item.centerSet, 'confirmed', 'needs confirmation');
    lines = { ...
        sprintf('Image %d of %d: %s', currentIndex, numel(items), ...
        labkit.image.displayName(item.path)), ...
        sprintf('Crop center: x %.1f, y %.1f (%s)', ...
        item.centerXY(1), item.centerXY(2), stateText), ...
        sprintf('Output size: %d x %d px; rotation: %.3g deg; padding: %.3g%%', ...
        cropWidth, cropHeight, item.angleDeg, paddingPercent)};
    lastExport = state.project.results.lastExport;
    if ~isempty(lastExport)
        lines{end+1} = sprintf( ...
            'Last manifest: %s', char(lastExport.manifestPath));
    end
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
