% Private filePanel helper. Expected caller: buildFilePanelControl. Input is a
% uigetfile-style filter spec. Output is a normalized filter accepted by
% uigetfile and recursive file-pattern expansion.
function filters = normalizeFilePanelFilters(filters)
    if iscell(filters) && numel(filters) == 1 && iscell(filters{1})
        filters = filters{1};
    end
    if ischar(filters)
        return;
    end
    if isstring(filters)
        if isscalar(filters)
            filters = char(filters);
            return;
        end
        filters = cellstr(filters);
    end
    if iscell(filters)
        filters = cellfun(@(value) char(string(value)), filters, ...
            'UniformOutput', false);
    end
end
