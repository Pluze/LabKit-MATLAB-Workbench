% Expected caller: FLIR thermal app UI and tests. Inputs are app items,
% current selection, and export folder. Output is status-panel text.
function lines = detailLines(items, currentIndex, outputFolder)

    if isempty(items)
        lines = {
            'No FLIR radiometric images loaded.'
            'Load original FLIR JPG/RJPEG files, not exported screenshots.'
            ['Output folder: ' char(string(outputFolder))]};
        return;
    end
    currentIndex = max(1, min(currentIndex, numel(items)));
    item = items(currentIndex);
    range = double(item.displayRange(:)).';
    lines = {
        sprintf('Loaded files: %d', numel(items))
        sprintf('Current file: %s', char(item.name))
        sprintf('Range status: %s', rangeStatus(item))
        sprintf('Display range: %.3g to %.3g %s', ...
        range(1), range(2), char(string(item.units)))
        sprintf('Reader: %s', metadataText(item, 'reader'))
        sprintf('Raw byte order: %s', metadataText(item, 'rawByteOrder'))
        sprintf('Message: %s', char(string(item.message)))
        ['Output folder: ' char(string(outputFolder))]};
end

function text = rangeStatus(item)
    if isfield(item, 'rangeAdjusted') && logical(item.rangeAdjusted)
        text = 'range set';
    else
        text = 'needs range';
    end
end

function text = metadataText(item, field)
    text = "-";
    if isfield(item, 'metadata') && isfield(item.metadata, field)
        text = char(string(item.metadata.(field)));
    end
end
