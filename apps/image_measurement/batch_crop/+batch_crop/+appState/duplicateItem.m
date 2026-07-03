% App-owned state helper. Expected caller: batch-crop app duplicate callback
% and package tests. Input is one loaded crop item. Output is a new crop item
% for the same source image with independent crop-center confirmation state.
function item = duplicateItem(sourceItem)
%DUPLICATEITEM Duplicate one loaded image as a new crop task.

    item = sourceItem;
    item.centerXY = [NaN, NaN];
    item.centerSet = false;
end
