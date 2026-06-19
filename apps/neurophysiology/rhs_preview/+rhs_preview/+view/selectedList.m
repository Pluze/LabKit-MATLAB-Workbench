% Expected caller: rhs_preview.run. Input is one selected path string. Output
% is a one-item display list or an empty string list for pathPanel controls.
function items = selectedList(pathValue)
%SELECTEDLIST Build a filename-only selected-file list.

    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        items = strings(0, 1);
    else
        items = rhs_preview.view.displayFile(pathValue);
    end
end
