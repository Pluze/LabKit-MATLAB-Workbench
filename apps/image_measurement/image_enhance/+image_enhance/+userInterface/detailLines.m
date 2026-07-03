% Expected caller: labkit_ImageEnhance_app summary pane. Inputs are loaded
% items, selection index, history steps, and last batch export payload.
function lines = detailLines(items, currentIndex, steps, lastExport)

    if isempty(items)
        lines = {'Load one or more images to begin enhancement.'};
        return;
    end

    item = items(currentIndex);
    lines = { ...
        sprintf('Selected: %s', char(item.name)), ...
        sprintf('Images loaded: %d', numel(items)), ...
        sprintf('History steps: %d', numel(steps))};
    if ~isempty(steps)
        lines{end + 1} = sprintf('Last step: %s', ...
            char(image_enhance.analysisRun.describeStep(steps(end))));
    end
    if ~isempty(lastExport) && isfield(lastExport, 'manifestPath')
        lines{end + 1} = sprintf('Last manifest: %s', char(lastExport.manifestPath));
    end
end
