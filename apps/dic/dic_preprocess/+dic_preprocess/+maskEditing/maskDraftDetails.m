% Expected caller: DIC preprocess runner and direct unit tests. Input is the
% current mask anchor array. Output is the detail text shown while editing an ROI
% boundary. Side effects: none.

function lines = maskDraftDetails(maskPoints)
%MASKDRAFTDETAILS Build DIC preprocess mask-anchor detail text.

    n = size(maskPoints, 1);
    if n >= 3
        lines = {sprintf( ...
            'Mask ROI anchors: %d. Preview, Add to mask, or Subtract from mask.', ...
            n)};
    else
        lines = {sprintf( ...
            'Mask ROI anchors: %d. Double-click the reference preview to add anchors; at least 3 anchors are required.', ...
            n)};
    end
end
