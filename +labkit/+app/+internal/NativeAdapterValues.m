% Normalize and validate values for the owning internal class.
% Expected callers are internal class methods; inputs and outputs retain
% their declared MATLAB shapes. Methods have no side effects except
% raising stable contract errors for malformed values.
classdef (Sealed, Hidden) NativeAdapterValues
    methods (Static)
        function policy = layoutPolicy()
            policy = nativeLayoutPolicy();
        end

        function fitText(component, options)
            arguments
                component
                options.CharsPerStep = []
                options.MaxShrinkSteps = []
            end
            supplied = {};
            if ~isempty(options.CharsPerStep)
                supplied(end + 1:end + 2) = { ...
                    "CharsPerStep", options.CharsPerStep};
            end
            if ~isempty(options.MaxShrinkSteps)
                supplied(end + 1:end + 2) = { ...
                    "MaxShrinkSteps", options.MaxShrinkSteps};
            end
            applyTextFit(component, supplied{:});
        end

        function installColumnDivider(figureHandle, grid, left, right)
            installColumnResize(figureHandle, grid, left, right);
        end

        function installRowDivider(figureHandle, grid, upper, lower)
            installRowResize(figureHandle, grid, upper, lower);
        end

        function controller = interactionController( ...
                figureHandle, targets, dispatch)
            controller = InteractionController( ...
                figureHandle, targets, dispatch);
        end

        function parent = labeledParent(parent, label, id)
        policy = nativeLayoutPolicy();
        grid = uigridlayout(parent, [1 2], Padding=[0 0 0 0], ...
            ColumnSpacing=8, ColumnWidth={policy.FormLabelWidth, '1x'});
        tag = "";
        if strlength(string(id)) > 0
            tag = string(id) + ".label";
            grid.Tag = char(string(id) + ".layout");
        end
        labelHandle = uilabel(grid, Text=char(string(label)), Tag=char(tag), ...
            HorizontalAlignment="right");
        applyTextFit(labelHandle);
        grid.UserData = struct("Label", labelHandle);
        parent = grid;
        end

        function operations = orderedOperations(operations)
        if isempty(operations)
            return;
        end

        priority = zeros(1, numel(operations));
        for k = 1:numel(operations)
            switch operations{k}.Kind
                case {"choices", "limits", "filePaths", "tableData"}
                    priority(k) = 1;
                case "fileItemStatuses"
                    priority(k) = 2;
                case "value"
                    priority(k) = 2;
                case {"listSelection", "tableCellSelection"}
                    priority(k) = 3;
                otherwise
                    priority(k) = 4;
            end
        end
        [~, order] = sort(priority, "ascend");
        operations = operations(order);
        end

        function tf = isInteractionKind(kind)
        tf = any(string(kind) == [ ...
            "anchorPath", "pairedAnchors", "pointSlots", "rectangle", ...
            "regionSelection", "interval", "scaleReference"]);
        end

        function plan = validatePlan(plan)
        if ~isstruct(plan) || ~isscalar(plan) || ~isfield(plan, "Nodes")
            error("labkit:app:contract:InvalidValue", ...
                "MATLAB platform adapter requires a compiled Application plan.");
        end
        end

        function value = onOff(value)
        if value
            value = "on";
        else
            value = "off";
        end
        end

        function setIfProperty(component, name, value)
        if ~isprop(component, name) || isequaln(component.(name), value)
            return
        end
        component.(name) = value;
        end

        function label = linkedLabel(component)
        label = [];
        if isempty(component) || ~isvalid(component) || ...
                ~isprop(component, "UserData") || ...
                ~isstruct(component.UserData) || ...
                ~isfield(component.UserData, "LayoutContainer")
            return
        end
        container = component.UserData.LayoutContainer;
        if isempty(container) || ~isvalid(container) || ...
                ~isprop(container, "UserData") || ...
                ~isstruct(container.UserData) || ...
                ~isfield(container.UserData, "Label")
            return
        end
        candidate = container.UserData.Label;
        if ~isempty(candidate) && isvalid(candidate)
            label = candidate;
        end
        end

        function handle = layoutHandle(component)
        handle = component;
        if ~isprop(component, "UserData") || ~isstruct(component.UserData)
            return
        end
        if isfield(component.UserData, "LayoutContainer")
            candidate = component.UserData.LayoutContainer;
        elseif isfield(component.UserData, "Panel")
            candidate = component.UserData.Panel;
        else
            return
        end
        if ~isempty(candidate) && isvalid(candidate)
            handle = candidate;
        end
        end

        function slider = linkedPannerSlider(component)
        slider = [];
        if ~isprop(component, "UserData") || ~isstruct(component.UserData) || ...
                ~isfield(component.UserData, "Slider")
            return
        end
        candidate = component.UserData.Slider;
        if ~isempty(candidate) && isvalid(candidate)
            slider = candidate;
        end
        end

        function field = linkedRangeEnd(component)
        field = [];
        if ~isprop(component, "UserData") || ~isstruct(component.UserData) || ...
                ~isfield(component.UserData, "EndField")
            return
        end
        candidate = component.UserData.EndField;
        if ~isempty(candidate) && isvalid(candidate)
            field = candidate;
        end
        end

        function mode = linkedPlotMode(component)
        mode = [];
        if isempty(component) || ~isvalid(component) || ...
                ~isstruct(component.UserData) || ...
                ~isfield(component.UserData, "ValueControl")
            return
        end
        candidate = component.UserData.ValueControl;
        if ~isempty(candidate) && isvalid(candidate)
            mode = candidate;
        end
        end

        function sizes = repeatedOrConfigured(configured, count)
        sizes = repmat({'1x'}, 1, count);
        if ~isempty(configured)
            sizes = configured;
        end
        end

        function value = axisText(configured, fallback, index)
        value = "";
        if ~isempty(configured)
            value = configured(index);
        elseif ~isempty(fallback)
            value = fallback(index);
        end
        value = char(value);
        end

        function value = changingValue(event, fallback)
        value = fallback;
        if isstruct(event) && isfield(event, "Value")
            value = event.Value;
        elseif isobject(event) && isprop(event, "Value")
            value = event.Value;
        end
        end

        function applyChoices(component, choices)
        if ~isprop(component, "Items")
            return;
        end
        incoming = reshape(string(choices), 1, []);
        if isprop(component, "Value") && ~isempty(incoming)
            current = string(component.Value);
            if isscalar(current) && ~any(incoming == current)
                component.Items = unique([current, incoming], "stable");
                component.Value = incoming(1);
            end
        end
        component.Items = choices;
        end

        function [limits, value] = sliderInitialValue(config)
        limits = config.Limits;
        if isempty(limits)
            limits = [0 1];
        end
        value = config.Value;
        if isempty(value)
            value = limits(1);
        end
        end

        function [limits, value] = rangeSliderInitialValue(config)
        limits = config.Limits;
        if isempty(limits)
            limits = [0 1];
        end
        value = config.Value;
        if isempty(value)
            value = limits;
        end
        end

        function value = neutralValue(value, kind, choices)
        if ~isempty(value)
            return;
        end
        switch kind
            case "numeric"
                value = 0;
            case "choice"
                if isempty(choices)
                    value = "";
                else
                    value = choices(1);
                end
            case "logical"
                value = false;
            otherwise
                value = "";
        end
        end

        function key = axisKey(target, axisId)
        key = string(target) + "." + string(axisId);
        end

        function viewport = captureViewport(axes)
        viewport = repmat(struct("XLim", [], "YLim", [], ...
            "XLimMode", "", "YLimMode", ""), 1, numel(axes));
        for k = 1:numel(axes)
            viewport(k) = struct("XLim", axes(k).XLim, "YLim", axes(k).YLim, ...
                "XLimMode", axes(k).XLimMode, "YLimMode", axes(k).YLimMode);
        end
        end

        function restoreViewport(axes, viewport)
        for k = 1:numel(axes)
            if viewport(k).XLimMode == "manual"
                axes(k).XLim = viewport(k).XLim;
                axes(k).XLimMode = "manual";
            end
            if viewport(k).YLimMode == "manual"
                axes(k).YLim = viewport(k).YLim;
                axes(k).YLimMode = "manual";
            end
        end
        end

        function indices = selectedIndices(list)
        if isstruct(list.UserData) && isfield(list.UserData, "Paths") && ...
                isempty(list.UserData.Paths)
            indices = zeros(1, 0);
            return
        end
        items = string(list.Items);
        values = string(list.Value);
        indices = find(ismember(items, values));
        indices = reshape(indices, 1, []);
        end

        function cells = tableSelectionCells(event)
        if isstruct(event)
            if isfield(event, "Selection")
                cells = event.Selection;
            elseif isfield(event, "Indices")
                cells = event.Indices;
            else
                cells = zeros(0, 2);
            end
        elseif isprop(event, "Selection")
            cells = event.Selection;
        elseif isprop(event, "Indices")
            cells = event.Indices;
        else
            cells = zeros(0, 2);
        end
        if isempty(cells)
            cells = zeros(0, 2);
        elseif ~isnumeric(cells)
            rows = [cells.Row];
            columns = [cells.Column];
            cells = [rows(:), columns(:)];
        end
        cells = double(cells);
        end

        function value = editedValue(event)
        if isstruct(event)
            if isfield(event, "NewData")
                value = event.NewData;
            else
                value = event.EditData;
            end
        elseif isprop(event, "NewData")
            value = event.NewData;
        else
            value = event.EditData;
        end
        end

        function value = tableLabel(labels, index)
        value = "";
        if index < 1 || index > numel(labels)
            return;
        end
        candidate = string(labels(index));
        if isscalar(candidate)
            value = candidate;
        end
        end

        function value = nativeTableData(value)
        if ~iscell(value)
            return;
        end
        for k = 1:numel(value)
            item = value{k};
            if isempty(item)
                value{k} = '';
            elseif ischar(item)
                continue;
            elseif (isnumeric(item) || islogical(item)) && isscalar(item)
                continue;
            elseif isscalar(item)
                text = string(item);
                if ismissing(text)
                    value{k} = '';
                else
                    value{k} = char(text);
                end
            else
                error("labkit:app:contract:InvalidValue", ...
                    "Table cells must contain scalar display values.");
            end
        end
        end

        function value = multiSelectValue(selectionMode)
        if selectionMode == "multiple"
            value = "on";
        else
            value = "off";
        end
        end

        function value = dialogFilters(filters)
        filters = textColumn(filters);
        if isempty(filters)
            value = "*.*";
        elseif mod(numel(filters), 2) == 0
            value = reshape(cellstr(filters), 2, []).';
        else
            value = cellstr(filters);
        end
        end

        function paths = filesInFolder(folder, filters, recursive)
        filters = textColumn(filters);
        if mod(numel(filters), 2) == 0
            filters = filters(1:2:end);
        end
        patterns = strings(0, 1);
        for filter = filters.'
            patterns = [patterns; split(filter, ";")];
        end
        patterns = unique(strtrim(patterns(strlength(strtrim(patterns)) > 0)), ...
            "stable");
        parts = cell(numel(patterns), 1);
        for k = 1:numel(patterns)
            if recursive
                entries = dir(fullfile(folder, "**", patterns(k)));
            else
                entries = dir(fullfile(folder, patterns(k)));
            end
            entries = entries(~[entries.isdir]);
            values = strings(numel(entries), 1);
            for index = 1:numel(entries)
                values(index) = string(fullfile( ...
                    entries(index).folder, entries(index).name));
            end
            parts{k} = values;
        end
        if isempty(parts)
            paths = strings(0, 1);
        else
            paths = sort(unique(vertcat(parts{:}), "stable"));
        end
        end

        function path = safeStartPath(value)
        path = char(string(value));
        if isempty(path) || ~isfolder(path)
            path = pwd;
        end
        end

        function result = dialogPath(name, folder)
        if isequal(name, 0)
            result = labkit.app.dialog.Choice("", Cancelled=true);
        else
            result = labkit.app.dialog.Choice(string(folder) + filesep + string(name));
        end
        end

        function result = folderDialogPath(folder)
        if isequal(folder, 0)
            result = labkit.app.dialog.Choice("", Cancelled=true);
        else
            result = labkit.app.dialog.Choice(string(folder));
        end
        end

        function position = closePromptPosition(fig)
        width = 430;
        height = 118;
        figurePosition = fig.Position;
        promptWidth = min(width, max(160, figurePosition(3) - 24));
        x = max(12, (figurePosition(3) - promptWidth) / 2);
        y = max(12, figurePosition(4) - height - 44);
        position = [x y promptWidth height];
        end

        function labels = formatFileLabels(paths, statuses)
        paths = textColumn(paths);
        if nargin < 2 || isempty(statuses)
            statuses = strings(size(paths));
        else
            statuses = textColumn(statuses);
        end
        if numel(statuses) ~= numel(paths)
            error("labkit:app:contract:InvalidValue", ...
                "File item statuses must be empty or match file paths.");
        end
        names = strings(size(paths));
        parents = strings(size(paths));
        for k = 1:numel(paths)
            [folder, base, extension] = fileparts(char(paths(k)));
            names(k) = string(base) + string(extension);
            [~, parents(k)] = fileparts(folder);
        end
        width = max(2, strlength(string(max(1, numel(paths)))));
        labels = strings(size(paths));
        for k = 1:numel(paths)
            suffix = "";
            if nnz(names == names(k)) > 1 && strlength(parents(k)) > 0
                suffix = " (" + parents(k) + ")";
            end
            labels(k) = compose("%0" + width + "d %s%s", ...
                k, names(k), suffix);
            if strlength(statuses(k)) > 0
                labels(k) = labels(k) + " [" + statuses(k) + "]";
            end
        end
        labels = reshape(labels, 1, []);
        end

        function height = estimatedControlHeight(text, charsPerLine, maxLines, minimum)
        text = string(text);
        if isempty(text)
            height = minimum;
            return
        end
        lines = splitlines(text(:));
        lineCount = max(1, ceil(double(max(strlength(lines))) / charsPerLine));
        lineCount = min(maxLines, lineCount);
        height = max(minimum, 20 * lineCount + 6);
        end

        function folder = userDialogFolder()
        folder = string(getenv("USERPROFILE"));
        if strlength(folder) == 0 || ~isfolder(folder)
            folder = string(getenv("HOME"));
        end
        if strlength(folder) == 0 || ~isfolder(folder)
            folder = string(tempdir);
        end
        folder = char(folder);
        end

        function mode = startupGuiMode()
        mode = lower(strip(string(getenv("LABKIT_GUI_TEST_MODE"))));
        if strlength(mode) == 0
            mode = "visible";
        end
        end

        function message = deepestCauseMessage(cause)
        message = string(cause.message);
        while ~isempty(cause.cause)
            cause = cause.cause{1};
            message = string(cause.message);
        end
        end

        function filepath = plotFilepath(basePath, axesHandle, index)
        [folder, name, extension] = fileparts(basePath);
        label = join(string(axesHandle.Title.String), " ");
        label = string(matlab.lang.makeValidName(char(label)));
        if strlength(label) == 0
            label = "plot" + string(index);
        end
        filepath = string(fullfile(folder, sprintf( ...
            "%s_%02d_%s%s", name, index, label, extension)));
        end

    end
end

function values = textColumn(values)
if isempty(values)
    values = strings(0, 1);
elseif ischar(values)
    values = string(values);
else
    values = string(values(:));
end
end
