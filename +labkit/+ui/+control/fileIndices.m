function idx = fileIndices(files, itemCount)
%FILEINDICES Return bounded indices from filePanel file-entry structs.
%
% App-facing contract:
%   idx = labkit.ui.control.fileIndices(files, itemCount)
%
% Inputs:
%   files - file-entry struct array emitted by filePanel events or returned
%       by getFiles. Entries may expose index or id fields.
%   itemCount - current number of app-owned items that file entries refer to.
%
% Output:
%   idx - stable numeric column of unique indices within 1:itemCount.

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
