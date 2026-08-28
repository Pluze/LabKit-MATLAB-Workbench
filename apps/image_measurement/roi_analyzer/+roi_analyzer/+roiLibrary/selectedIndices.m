function indices = selectedIndices(selection, roiCount)
%SELECTEDINDICES Return valid selected ROI rows in stable order.
indices = zeros(1, 0);
if isstruct(selection) && isfield(selection, "roiIndices")
    indices = double(selection.roiIndices(:).');
end
if isempty(indices) && isstruct(selection) && isfield(selection, "roiIndex")
    indices = double(selection.roiIndex);
end
indices = unique(round(indices), "stable");
indices = indices(isfinite(indices) & indices >= 1 & indices <= roiCount);
end
