function spec = filePanel(id, labelText, varargin)
%FILEPANEL Create a file input panel spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.filePanel(id, label, "filters", filters, callbacks...)
%
% Inputs:
%   id - globally unique file-panel id.
%   labelText - panel label.
%   mode - "multi" or "single". Multi mode supports file multiselect and
%       recursive folder scans. Single mode opens one file and replaces the
%       previous file without remove/clear controls. Defaults to "multi".
%   filters - uigetfile-style file filters used for file selection and
%       recursive folder expansion in multi mode.
%   selectionMode - single or multiple list selection behavior in multi
%       mode. Defaults to single.
%   maxFiles - maximum number of file entries retained after add in multi
%       mode. Inf means no cap. Single mode always keeps one file.
%   folderWarningThreshold - recursive folder matches above this count
%       prompt the user for confirmation before file entries are accepted.
%   folderWarningProvider - optional function handle
%       continue = f(folder, fileCount, threshold) used to customize or test
%       large-folder confirmation.
%   chooseLabel, removeLabel, clearLabel, status, emptyText, onChoose,
%       onRemove, onSelectionChange, onClear - optional semantic props.
%
% Callback events:
%   onChoose receives event.files, event.addedFiles, event.selectedFiles, and
%       event.value as selected file-entry structs.
%   onRemove receives event.files, event.removedFiles, event.selectedFiles,
%       and event.value as selected file-entry structs after removal.
%   File entries expose id, index, path, name, displayName, and status.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.mode = char(string(optionValue(props, 'mode', 'multi')));
    validateMode(props.mode);
    props.selectionMode = char(string(optionValue(props, ...
        'selectionMode', 'single')));
    validateSelectionMode(props.selectionMode);
    props.maxFiles = optionValue(props, 'maxFiles', Inf);
    validateMaxFiles(props.maxFiles);
    props.folderWarningThreshold = optionValue(props, ...
        'folderWarningThreshold', 500);
    validateWarningThreshold(props.folderWarningThreshold);
    spec = makeSpec('filePanel', id, props, {}, struct());
end

function validateMode(mode)
    allowed = {'multi', 'single'};
    if ~any(strcmp(mode, allowed))
        error('labkit:ui:spec:InvalidFilePanelMode', ...
            'Unsupported filePanel mode "%s".', mode);
    end
end

function validateSelectionMode(mode)
    allowed = {'single', 'multiple'};
    if ~any(strcmp(mode, allowed))
        error('labkit:ui:spec:InvalidFilePanelSelectionMode', ...
            'Unsupported filePanel selectionMode "%s".', mode);
    end
end

function validateMaxFiles(value)
    if ~(isnumeric(value) && isscalar(value) && value >= 1)
        error('labkit:ui:spec:InvalidFilePanelMaxFiles', ...
            'filePanel maxFiles must be a positive scalar.');
    end
end

function validateWarningThreshold(value)
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value >= 0)
        error('labkit:ui:spec:InvalidFilePanelWarningThreshold', ...
            'filePanel folderWarningThreshold must be a nonnegative scalar.');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
