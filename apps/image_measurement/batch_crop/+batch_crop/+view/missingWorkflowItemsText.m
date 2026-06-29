% App-owned export validation text helper. Expected caller: batch-crop export
% callback and unit tests. Inputs are crop items and a missing-kind label.
% Output is a concise user-facing message listing the affected files.
function text = missingWorkflowItemsText(items, missingKind)
%MISSINGWORKFLOWITEMSTEXT Build a missing-center/scale export prompt.

    missingKind = string(missingKind);
    names = missingItemNames(items, missingKind);
    if isempty(names)
        text = "";
        return;
    end

    switch lower(missingKind)
        case "center"
            intro = "Set or confirm the crop center for these image(s) before exporting:";
        case "scale"
            intro = "Set a valid scale calibration for these image(s) before exporting in Physical mode:";
        otherwise
            intro = "Complete the required setup for these image(s) before exporting:";
    end

    text = intro + newline + " - " + strjoin(names, newline + " - ");
end

function names = missingItemNames(items, missingKind)
    names = strings(0, 1);
    for k = 1:numel(items)
        if isMissing(items(k), missingKind)
            names(end + 1, 1) = batch_crop.view.displayNameFromPath(items(k).path);
        end
    end
end

function tf = isMissing(item, missingKind)
    switch lower(string(missingKind))
        case "center"
            tf = ~isfield(item, 'centerSet') || ~logical(item.centerSet);
        case "scale"
            tf = ~isfield(item, 'scaleCalibration') || ...
                ~batch_crop.state.isScaleCalibrationSet(item.scaleCalibration);
        otherwise
            tf = false;
    end
end
