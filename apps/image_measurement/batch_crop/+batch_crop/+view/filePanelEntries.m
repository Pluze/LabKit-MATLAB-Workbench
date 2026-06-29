% App-owned file-list view helper. Expected caller: batch-crop runner refresh
% logic and package tests. Inputs are crop items and the current scale mode.
% Output is filePanel entry structs with user-facing workflow status labels.
function entries = filePanelEntries(items, scaleMode)
%FILEPANELENTRIES Build filePanel entries with crop readiness status labels.

    entries = repmat(struct('path', "", 'status', ""), numel(items), 1);
    physicalMode = strcmpi(string(scaleMode), "Physical");
    for k = 1:numel(items)
        entries(k).path = string(items(k).path);
        entries(k).status = itemStatus(items(k), physicalMode);
    end
end

function status = itemStatus(item, physicalMode)
    if ~isfield(item, 'centerSet') || ~logical(item.centerSet)
        status = "needs center";
        return;
    end
    if physicalMode && ~batch_crop.state.isScaleCalibrationSet(item.scaleCalibration)
        status = "needs scale";
        return;
    end
    status = "ready";
end
