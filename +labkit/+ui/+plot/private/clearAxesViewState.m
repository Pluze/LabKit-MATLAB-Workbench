% Private UI plot axes helper. Expected caller: labkit.ui.control or labkit.ui.plot axes and image
% lifecycle helpers. Input is an axes handle. Side effect clears LabKit's
% cached image-view bounds so future redraws compute a fresh home view.
function clearAxesViewState(ax)
    key = 'labkitImageViewBounds';
    if isappdata(ax, key)
        rmappdata(ax, key);
    end
end
