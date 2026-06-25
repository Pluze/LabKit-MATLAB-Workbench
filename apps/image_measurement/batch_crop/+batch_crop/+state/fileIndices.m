% Expected caller: batch_crop.run filePanel callbacks. Inputs are filePanel
% file-entry structs and the current item count. Output is a stable numeric index
% vector bounded to existing app items. No UI state is read or changed.
function idx = fileIndices(files, itemCount)
%FILEINDICES Return app item indices from filePanel file entries.

    idx = zeros(numel(files), 1);
    for k = 1:numel(files)
        if isfield(files(k), 'index')
            indexValue = double(files(k).index);
            if isscalar(indexValue) && isfinite(indexValue)
                idx(k) = indexValue;
                continue;
            end
        end
        if isfield(files(k), 'id')
            token = regexp(char(string(files(k).id)), '^file(\d+)$', ...
                'tokens', 'once');
            if ~isempty(token)
                idx(k) = str2double(token{1});
            end
        end
    end
    idx = unique(idx(idx >= 1 & idx <= itemCount), 'stable');
end
