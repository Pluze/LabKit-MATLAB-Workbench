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
    labels = flir_thermal.userInterface.rangeControlLabels();
    lines = {
        sprintf('Loaded files: %d', numel(items))
        sprintf('Current file: %s', char(item.name))
        sprintf('Range status: %s', rangeStatus(item))
        sprintf('Display range: %.3g to %.3g %s', ...
        range(1), range(2), char(string(item.units)))
        sprintf('Image hot spot: %s', pointText(item, 'hotSpot'))
        sprintf('Image cold spot: %s', pointText(item, 'coldSpot'))
        sprintf('Manual point: %s', pointText(item, 'manualPoint'))
        sprintf('%s: %s', char(labels.roiHotSpot), pointText(item, 'roiHotSpot'))
        sprintf('%s: %s', char(labels.roiColdSpot), pointText(item, 'roiColdSpot'))
        sprintf('%s: %s', char(labels.roiMean), roiText(item, 'roiMean'))
        sprintf('Temperature differences: %s', differenceSummary(item))
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

function text = pointText(item, field)
    text = "-";
    if ~isfield(item, field)
        return;
    end
    reading = item.(field);
    if ~isPointReading(reading)
        return;
    end
    text = sprintf('x %.0f, y %.0f, %.2f C', ...
        reading.x, reading.y, reading.temperatureC);
end

function text = roiText(item, field)
    text = "-";
    if ~isfield(item, field)
        return;
    end
    reading = item.(field);
    if ~isRoiReading(reading)
        return;
    end
    text = sprintf('x %.0f, y %.0f, %.0f x %.0f px, %.2f C', ...
        reading.x, reading.y, reading.width, reading.height, ...
        reading.temperatureC);
end

function text = differenceSummary(item)
    labels = flir_thermal.userInterface.rangeControlLabels();
    names = ["image hot", "image cold", "manual", ...
        labels.roiHotSpot, labels.roiColdSpot, labels.roiMean];
    values = [
        readingTemperature(item, 'hotSpot')
        readingTemperature(item, 'coldSpot')
        readingTemperature(item, 'manualPoint')
        readingTemperature(item, 'roiHotSpot')
        readingTemperature(item, 'roiColdSpot')
        readingTemperature(item, 'roiMean')];
    parts = strings(1, 0);
    for a = 1:numel(values)
        if ~isfinite(values(a))
            continue;
        end
        for b = a+1:numel(values)
            if ~isfinite(values(b))
                continue;
            end
            parts(end+1) = sprintf('%s - %s = %.2f C', ...
                names(a), names(b), values(a) - values(b));
        end
    end
    if isempty(parts)
        text = "-";
    else
        text = strjoin(parts, '; ');
    end
end

function value = readingTemperature(item, field)
    value = NaN;
    if isfield(item, field) && isstruct(item.(field)) && ...
            isfield(item.(field), 'temperatureC')
        value = double(item.(field).temperatureC);
    end
end

function tf = isPointReading(reading)
    tf = isstruct(reading) && all(isfield(reading, ...
        {'x', 'y', 'temperatureC'})) && ...
        all(isfinite([reading.x, reading.y, reading.temperatureC]));
end

function tf = isRoiReading(reading)
    tf = isstruct(reading) && all(isfield(reading, ...
        {'x', 'y', 'width', 'height', 'temperatureC'})) && ...
        all(isfinite([reading.x, reading.y, reading.width, ...
        reading.height, reading.temperatureC]));
end
