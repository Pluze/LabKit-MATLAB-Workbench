% App-owned export option factory. Expected caller: batch-crop runner. Inputs
% are sanitized UI values and current state. Output is the export options
% struct consumed by batch_crop.state.exportPlan and batch_crop.export.
function opts = exportOptions(outputFolder, formatValue, cropSize, paddingPercent, scaleMode, scaleUnit, physicalSize, targetPixelsPerUnit, maxUpsamplePercent)
%EXPORTOPTIONS Build a batch-crop export options snapshot.

    opts = struct();
    opts.outputFolder = outputFolder;
    opts.format = formatValue;
    opts.cropWidth = cropSize(1);
    opts.cropHeight = cropSize(2);
    opts.paddingPercent = paddingPercent;
    opts.scaleMode = scaleMode;
    opts.scaleUnit = scaleUnit;
    opts.physicalWidth = max(eps, double(physicalSize(1)));
    opts.physicalHeight = max(eps, double(physicalSize(2)));
    opts.targetPixelsPerUnit = max(0, double(targetPixelsPerUnit));
    opts.maxUpsamplePercent = max(0, double(maxUpsamplePercent));
end
