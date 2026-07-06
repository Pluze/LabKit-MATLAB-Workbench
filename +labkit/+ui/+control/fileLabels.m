function labels = fileLabels(paths, varargin)
%FILELABELS Build stable short labels for file paths.
%
% App-facing contract:
%   labels = labkit.ui.control.fileLabels(paths)
%   labels = labkit.ui.control.fileLabels(paths, "status", status)
%
% Inputs:
%   paths - char, string array, or cell array of file paths.
%   status - optional status label per path. Empty status values are omitted.
%
% Output:
%   labels - cell column of labels in the form "01 name.ext",
%       "02 name.ext (parent)", or "03 name.ext [status]".

    opts = parseOptions(varargin);
    paths = normalizePaths(paths);
    status = normalizeStatus(optionValue(opts, 'status', strings(0, 1)), numel(paths));
    names = baseNames(paths);
    disambiguators = disambiguatorsFor(paths, names);
    width = max(2, numel(char(string(numel(paths)))));
    labels = cell(numel(paths), 1);
    for k = 1:numel(paths)
        label = sprintf(['%0' num2str(width) 'd %s'], k, char(names(k)));
        if strlength(disambiguators(k)) > 0
            label = sprintf('%s (%s)', label, char(disambiguators(k)));
        end
        if strlength(status(k)) > 0
            label = sprintf('%s [%s]', label, char(status(k)));
        end
        labels{k} = label;
    end
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:control:InvalidFileLabelOptions', ...
            'fileLabels options must be name/value pairs.');
    end
    opts = struct();
    for k = 1:2:numel(args)
        opts.(char(string(args{k}))) = args{k + 1};
    end
end

function paths = normalizePaths(paths)
    if isempty(paths)
        paths = strings(0, 1);
    elseif ischar(paths)
        paths = string({paths});
    elseif isstring(paths)
        paths = paths(:);
    elseif iscell(paths)
        paths = string(paths(:));
    else
        error('labkit:ui:control:InvalidFileLabelPaths', ...
            'fileLabels paths must be char, string, or a cell array.');
    end
    paths = paths(strlength(paths) > 0);
end

function status = normalizeStatus(status, count)
    if isempty(status)
        status = strings(count, 1);
    elseif ischar(status)
        status = repmat(string(status), count, 1);
    elseif isstring(status)
        status = status(:);
    elseif iscell(status)
        status = string(status(:));
    else
        status = strings(count, 1);
    end
    if numel(status) == 1 && count > 1
        status = repmat(status, count, 1);
    end
    if numel(status) ~= count
        error('labkit:ui:control:InvalidFileLabelStatus', ...
            'fileLabels status must be empty, scalar, or match paths.');
    end
end

function names = baseNames(paths)
    names = strings(numel(paths), 1);
    for k = 1:numel(paths)
        [~, base, ext] = fileparts(char(paths(k)));
        names(k) = string([base ext]);
        if strlength(names(k)) == 0
            names(k) = paths(k);
        end
    end
end

function labels = disambiguatorsFor(paths, names)
    labels = strings(numel(paths), 1);
    for k = 1:numel(paths)
        same = find(names == names(k));
        if numel(same) < 2
            continue;
        end
        labels(k) = shortestUniqueParent(paths(k), paths(same));
    end
end

function label = shortestUniqueParent(pathValue, peerPaths)
    parts = parentParts(pathValue);
    peerParts = cell(numel(peerPaths), 1);
    for k = 1:numel(peerPaths)
        peerParts{k} = parentParts(peerPaths(k));
    end

    label = "";
    for depth = 1:max(1, numel(parts))
        candidate = suffixParts(parts, depth);
        uniqueCandidate = true;
        for k = 1:numel(peerParts)
            if string(peerPaths(k)) == string(pathValue)
                continue;
            end
            if candidate == suffixParts(peerParts{k}, depth)
                uniqueCandidate = false;
                break;
            end
        end
        if uniqueCandidate || depth == numel(parts)
            label = candidate;
            return;
        end
    end
end

function parts = parentParts(pathValue)
    [folder, ~, ~] = fileparts(char(pathValue));
    if isempty(folder)
        parts = strings(0, 1);
        return;
    end
    folder = strrep(folder, '\', filesep);
    raw = split(string(folder), filesep);
    raw = raw(strlength(raw) > 0);
    if isempty(raw)
        parts = string(folder);
    else
        parts = raw(:);
    end
end

function text = suffixParts(parts, depth)
    if isempty(parts)
        text = "";
        return;
    end
    depth = min(depth, numel(parts));
    text = strjoin(parts(end-depth+1:end), filesep);
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
