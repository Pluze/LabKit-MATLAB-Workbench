classdef control
    %CONTROL Test-only access to framework-owned semantic control adapters.

    methods (Static)
        function value = getValue(ui, id)
            item = testui.control.resolve(ui, id);
            if isfield(item, 'getValue') && isa(item.getValue, 'function_handle')
                value = item.getValue();
            else
                handle = testui.control.valueHandle(item);
                value = handle.Value;
            end
        end

        function setValue(ui, id, value)
            item = testui.control.resolve(ui, id);
            if isfield(item, 'setValue') && isa(item.setValue, 'function_handle')
                item.setValue(value);
            else
                handle = testui.control.valueHandle(item);
                handle.Value = value;
            end
        end

        function files = getFiles(ui, id)
            item = testui.control.resolve(ui, id);
            files = item.currentFiles();
        end

        function paths = filePaths(files)
            if isempty(files)
                paths = strings(0, 1);
            else
                paths = string({files.path}).';
                paths = paths(strlength(paths) > 0);
            end
        end

        function setFileSelection(ui, id, files)
            item = testui.control.resolve(ui, id);
            item.setFileSelection(item, files);
            allFiles = item.currentFiles();
            selected = item.currentSelectedFiles();
            if isempty(selected)
                return;
            end
            index = find(string({allFiles.id}) == string(selected(1).id), ...
                1, 'first');
            context = struct('valid', true, 'filePanelId', string(id), ...
                'index', index, 'count', numel(allFiles), ...
                'name', string(selected(1).displayName));
            setappdata(ui.figure, 'labkitSelectedFileContext', context);
            suffix = sprintf('file %d/%d: %s', index, numel(allFiles), ...
                char(context.name));
            ui.figure.Name = regexprep(ui.figure.Name, ...
                '\s\|\sfile\s+\d+/\d+:\s.*$', '');
            ui.figure.Name = char(string(ui.figure.Name) + " | " + suffix);
        end

        function setItems(ui, id, items)
            item = testui.control.resolve(ui, id);
            handle = testui.control.valueHandle(item);
            previous = string(handle.Value);
            handle.Items = cellstr(string(items(:)));
            if any(string(handle.Items) == previous)
                handle.Value = char(previous);
            else
                handle.Value = handle.Items{1};
            end
        end

        function setEnabled(ui, id, enabled)
            item = testui.control.resolve(ui, id);
            handles = testui.control.handles(item);
            value = 'off';
            if logical(enabled)
                value = 'on';
            end
            for k = 1:numel(handles)
                if isprop(handles{k}, 'Enable')
                    handles{k}.Enable = value;
                end
            end
        end

        function setLimits(ui, id, limits)
            item = testui.control.resolve(ui, id);
            handles = testui.control.handles(item);
            for k = 1:numel(handles)
                handle = handles{k};
                if isprop(handle, 'Limits') && ...
                        (~isfield(item, 'slider') || ~isequal(handle, item.slider) || ...
                        all(isfinite(limits)))
                    handle.Limits = limits;
                    if isprop(handle, 'Value') && isnumeric(handle.Value) && ...
                            isscalar(handle.Value)
                        handle.Value = min(limits(2), max(limits(1), handle.Value));
                    end
                end
            end
        end

        function setListItems(ui, id, items)
            item = testui.control.resolve(ui, id);
            if isfield(item, 'kind') && strcmp(item.kind, 'filePanel')
                error('labkit:ui:control:FilePanelListItems', ...
                    'filePanel items are semantic file records.');
            end
            item.listbox.Items = cellstr(string(items(:)));
        end

        function appendLog(ui, id, message)
            item = testui.control.resolve(ui, id);
            old = item.textArea.Value;
            old{end + 1} = char(message);
            item.textArea.Value = old;
        end

        function labels = fileLabels(paths, varargin)
            status = strings(numel(paths), 1);
            if ~isempty(varargin)
                status = string(varargin{2}(:));
            end
            paths = string(paths(:));
            labels = strings(numel(paths), 1);
            [~, names, extensions] = arrayfun(@(p) fileparts(char(p)), ...
                paths, 'UniformOutput', false);
            names = string(names) + string(extensions);
            width = max(2, strlength(string(numel(paths))));
            for k = 1:numel(paths)
                suffix = "";
                peers = find(names == names(k));
                if numel(peers) > 1
                    [parent, ~, ~] = fileparts(char(paths(k)));
                    [~, parentName] = fileparts(parent);
                    suffix = " (" + string(parentName) + ")";
                end
                statusText = "";
                if strlength(status(k)) > 0
                    statusText = " [" + status(k) + "]";
                end
                format = sprintf('%%0%dd %%s%%s%%s', width);
                labels(k) = string(sprintf(format, k, char(names(k)), ...
                    char(suffix), char(statusText)));
            end
            labels = cellstr(labels);
        end
    end

    methods (Static, Access = private)
        function item = resolve(ui, id)
            item = ui.controls.(char(string(id)));
        end

        function handle = valueHandle(item)
            fields = {'valueHandle', 'handle', 'dropdown', 'listbox', ...
                'table', 'textArea', 'displayField'};
            for k = 1:numel(fields)
                if isfield(item, fields{k}) && ~isempty(item.(fields{k}))
                    handle = item.(fields{k});
                    return;
                end
            end
            error('LabKit:Tests:MissingValueHandle', ...
                'Semantic test control does not expose a value handle.');
        end

        function values = handles(item)
            names = fieldnames(item);
            values = {};
            for k = 1:numel(names)
                value = item.(names{k});
                if isscalar(value) && isgraphics(value)
                    values{end + 1} = value;
                end
            end
        end
    end
end
