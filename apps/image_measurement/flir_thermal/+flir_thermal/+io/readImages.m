% Expected caller: labkit_FLIRThermal_app and unit tests. Inputs are FLIR
% radiometric image paths and optional labkit.thermal read options. Outputs
% are an app-owned item struct array and a labkit.thermal import report.
% Non-compatible files are skipped by the thermal facade instead of aborting
% the whole import. No GUI side effects.
function [items, report] = readImages(paths, opts)

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    opts.SkipInvalid = true;
    [records, report] = labkit.thermal.readFiles(paths, opts);
    template = flir_thermal.state.emptyItem();
    items = repmat(template, numel(records), 1);
    for k = 1:numel(records)
        items(k) = itemFromRecord(records(k), template);
    end
end

function item = itemFromRecord(record, template)
    labels = flir_thermal.view.rangeControlLabels();
    item = template;
    item.path = record.path;
    item.name = record.name;
    item.format = record.format;
    item.raw = record.raw;
    item.temperatureC = record.temperatureC;
    [item.hotSpot, item.coldSpot] = ...
        flir_thermal.ops.extremeTemperatureReadings(record.temperatureC);
    item.displayRange = initialRange(item);
    item.rangePreset = labels.defaultPreset;
    item.rangeControlBounds = flir_thermal.view.rangeControlBounds( ...
        item, item.rangePreset, [-20 120]);
    item.rangeAdjusted = false;
    item.units = record.units;
    item.metadata = record.metadata;
    item.message = record.message;
end

function range = initialRange(item)
    values = flir_thermal.view.valueMatrix(item);
    values = values(isfinite(values));
    if isempty(values)
        range = [20 40];
        return;
    end
    range = [min(values), max(values)];
    if range(2) <= range(1)
        range(2) = range(1) + 1;
    end
end
