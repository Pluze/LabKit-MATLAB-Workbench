function currentIndex = refreshSingleSelectFileListbox(lb, loadedText, items, currentIndex)
%REFRESHSINGLESELECTFILELISTBOX Refresh a single-select file listbox.

    if isempty(items)
        lb.Items = {};
        lb.Value = {};
        loadedText.Value = 'No files loaded';
        currentIndex = [];
        return;
    end

    names = {items.name};
    lb.Items = names;
    if isempty(currentIndex) || currentIndex < 1 || currentIndex > numel(items)
        currentIndex = 1;
    end
    lb.Value = names{currentIndex};
    loadedText.Value = sprintf('%d file(s) loaded', numel(items));
end
