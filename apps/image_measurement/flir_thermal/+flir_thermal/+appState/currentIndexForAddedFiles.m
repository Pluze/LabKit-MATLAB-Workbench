% Expected caller: flir_thermal.definitionActions after a filePanel choose
% event. Inputs are filePanel added-file entries and loaded thermal items.
% Output is the selected item index for the first newly added file, falling
% back to the first loaded item when the event carries no usable index.
function idx = currentIndexForAddedFiles(addedFiles, items)
%CURRENTINDEXFORADDEDFILES Return the current index after appending files.

    idx = labkit.ui.control.fileIndices(addedFiles, numel(items));
    if isempty(idx)
        idx = 1;
        return;
    end
    idx = idx(1);
end
