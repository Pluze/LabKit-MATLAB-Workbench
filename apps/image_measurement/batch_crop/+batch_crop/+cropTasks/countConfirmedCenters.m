% App-owned crop-task query. Expected caller: batch-crop UI summary and tests.
% Input is a crop item struct vector. Output is the number of items with a
% confirmed crop center. No state is modified.
function count = countConfirmedCenters(items)
%COUNTCONFIRMEDCENTERS Count crop tasks with confirmed centers.

    count = 0;
    if ~isempty(items)
        count = sum([items.centerSet]);
    end
end
