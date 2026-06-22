% Expected caller: labkit_ImageMatch_app summary pane. Inputs are loaded
% items, selection index, reference item, history steps, and last batch export
% payload.
function lines = detailLines(items, currentIndex, referenceItem, steps, lastExport)

    if isempty(items) && isempty(referenceItem)
        lines = {'Load a reference image and one or more source images.'};
        return;
    elseif isempty(items)
        lines = {'Load one or more source images.'};
        return;
    elseif isempty(referenceItem)
        lines = {'Load a reference image before applying matches or exporting.'};
        return;
    end

    item = items(currentIndex);
    lines = { ...
        sprintf('Selected: %s', char(item.name)), ...
        sprintf('Reference: %s', char(referenceItem.name)), ...
        sprintf('Images loaded: %d', numel(items)), ...
        sprintf('History steps: %d', numel(steps))};
    if ~isempty(steps)
        lines{end + 1} = sprintf('Last step: %s', ...
            char(image_match.ops.describeStep(steps(end))));
    end
    if ~isempty(lastExport) && isfield(lastExport, 'manifestPath')
        lines{end + 1} = sprintf('Last manifest: %s', char(lastExport.manifestPath));
    end
end
