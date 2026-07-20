% App-owned scale status view helper. Expected caller: batch-crop app summary
% refresh. Inputs are state, current index, mode, physical size, and unit.
% Output is display text only.
function text = statusText(state, currentIndex, mode, physicalSize, unitName)
%SCALESTATUSTEXT Build the Scale tab status line.

    if ~strcmpi(string(mode), "Physical")
        text = 'Pixel mode: output size uses crop width/height in px.';
        return;
    end

    items = state.project.inputs.items;
    if isempty(items)
        text = sprintf('Physical mode: set %.6g x %.6g %s and load images.', ...
            physicalSize(1), physicalSize(2), char(string(unitName)));
        return;
    end

    scaleSummary = batch_crop.scaleCalibration.summarize(items);
    item = items(currentIndex);
    cal = item.scaleCalibration;
    if batch_crop.scaleCalibration.isSet(cal)
        cropPixelsPerUnit = batch_crop.cropGeometry.pixelsPerUnitForUnit(cal, unitName);
        text = sprintf(['Physical mode: crop %.6g x %.6g %s; image %d scale %.6g px/%s ' ...
            '(%.6g px/%s for crop); calibrated %d/%d.'], ...
            physicalSize(1), physicalSize(2), char(string(unitName)), ...
            currentIndex, cal.pixelsPerUnit, cal.unit, cropPixelsPerUnit, ...
            char(string(unitName)), scaleSummary.calibratedCount, scaleSummary.total);
    else
        text = sprintf('Physical mode: image %d needs scale; calibrated %d/%d.', ...
            currentIndex, scaleSummary.calibratedCount, scaleSummary.total);
    end
end
