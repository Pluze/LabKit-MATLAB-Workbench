classdef (Hidden, Sealed) SessionLogViewer < handle
    %SESSIONLOGVIEWER Native incremental viewer for one Runtime session.
    % MatlabPlatformAdapter owns this private tool window. It projects the
    % canonical retained history without mutating that history.

    properties (Access = private)
        Runtime
        Projection
        SubscriptionToken (1, 1) string = ""
        Figure
        RootPanel
        SummaryLabel
        NoticeLabel
        LevelFilter
        TraceButton
        CopyButton
        EventTable
        DetailArea
        VisibleSequences (1, :) double = zeros(1, 0)
        RefreshPump = []
        RefreshPending (1, 1) logical = false
        Closed (1, 1) logical = false
    end

    methods
        function obj = SessionLogViewer(runtime)
            if ~isa(runtime, "labkit.app.internal.runtime.RuntimeKernel") || ...
                    ~isscalar(runtime)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionLogViewer requires one RuntimeKernel.");
            end
            obj.Runtime = runtime;
            obj.Projection = labkit.app.internal.diagnostics.SessionLogProjection( ...
                runtime.diagnosticSnapshot());
            obj.createFigure();
            obj.RefreshPump = timer( ...
                "ExecutionMode", "singleShot", ...
                "StartDelay", 0.1, ...
                "TimerFcn", @(~, ~) obj.drainRefresh());
            obj.SubscriptionToken = ...
                runtime.subscribeDiagnostics(@obj.acceptRecord);
            obj.refresh();
        end

        function show(obj)
            if obj.Closed || isempty(obj.Figure) || ~isvalid(obj.Figure)
                return;
            end
            mode = ...
                labkit.app.internal.native.NativeAdapterValues.startupGuiMode();
            if mode == "hidden"
                return;
            end
            obj.Figure.Visible = "on";
            if mode == "minimized" && ...
                    isprop(obj.Figure, "WindowState")
                obj.Figure.WindowState = "minimized";
            end
            figure(obj.Figure);
        end

        function refresh(obj)
            if obj.Closed
                return;
            end
            obj.Projection.update(obj.Runtime.diagnosticSnapshot());
            obj.RefreshPending = false;
            obj.refreshView();
        end

        function figure = figureHandle(obj)
            figure = obj.Figure;
        end

        function tf = isOpen(obj)
            tf = ~obj.Closed && ~isempty(obj.Figure) && ...
                isvalid(obj.Figure);
        end

        function close(obj)
            if obj.Closed
                return;
            end
            obj.Closed = true;
            if strlength(obj.SubscriptionToken) > 0
                obj.Runtime.unsubscribeDiagnostics( ...
                    obj.SubscriptionToken);
            end
            obj.SubscriptionToken = "";
            pump = obj.RefreshPump;
            obj.RefreshPump = [];
            if ~isempty(pump) && isvalid(pump)
                stop(pump);
                delete(pump);
            end
            if ~isempty(obj.Figure) && isvalid(obj.Figure)
                delete(obj.Figure);
            end
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function createFigure(obj)
            obj.Figure = uifigure( ...
                Visible="off", ...
                Name=char(obj.Runtime.sessionLogTitle()), ...
                Position=viewerPosition(), ...
                AutoResizeChildren="off", ...
                CloseRequestFcn=@(~, ~) obj.close(), ...
                Tag="labkitSessionLogViewer");
            obj.RootPanel = uipanel(obj.Figure, ...
                BorderType="none", ...
                Position=[1 1 obj.Figure.Position(3:4)]);
            root = uigridlayout(obj.RootPanel, [5 1], ...
                RowHeight={30, 30, 36, "1x", 180}, ...
                Padding=[10 10 10 10], RowSpacing=6);

            obj.SummaryLabel = uilabel(root, ...
                Text="No retained events.", FontWeight="bold", ...
                Tag="labkitSessionLogSummary");
            obj.SummaryLabel.Layout.Row = 1;

            filters = uigridlayout(root, [1 2], ...
                ColumnWidth={115, 170}, ...
                Padding=[0 0 0 0], ColumnSpacing=5);
            filters.Layout.Row = 2;
            label = uilabel(filters, Text="Minimum severity");
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            obj.LevelFilter = uidropdown(filters, ...
                Items=["TRACE", "DEBUG", "INFO", "WARNING", ...
                    "ERROR", "CRITICAL"], ...
                ItemsData=["trace", "debug", "info", "warning", ...
                    "error", "critical"], ...
                Tooltip="Show retained events at or above this severity.", ...
                ValueChangedFcn=@(~, ~) obj.applyFilters(), ...
                Tag="labkitSessionLogLevel");
            obj.LevelFilter.Value = "trace";
            obj.LevelFilter.Layout.Row = 1;
            obj.LevelFilter.Layout.Column = 2;

            noticeGrid = uigridlayout(root, [1 4], ...
                ColumnWidth={"1x", 100, 80, 110}, ...
                Padding=[0 0 0 0], ColumnSpacing=6);
            noticeGrid.Layout.Row = 3;
            obj.NoticeLabel = uilabel(noticeGrid, ...
                Text="", FontColor=[0.45 0.25 0], ...
                Tag="labkitSessionLogNotices");
            obj.TraceButton = uibutton(noticeGrid, ...
                Text="Enable TRACE", ...
                ButtonPushedFcn=@(~, ~) obj.toggleTraceCapture(), ...
                Tag="labkitSessionLogTraceCapture");
            uibutton(noticeGrid, Text="Refresh", ...
                ButtonPushedFcn=@(~, ~) obj.refresh(), ...
                Tag="labkitSessionLogRefresh");
            obj.CopyButton = uibutton(noticeGrid, ...
                Text="Copy selected", Enable="off", ...
                ButtonPushedFcn=@(~, ~) obj.copyDetails(), ...
                Tag="labkitSessionLogCopy");
            obj.EventTable = uitable(root, ...
                Data=emptyRows(), ...
                ColumnName=["Time", "Level", "Area", "Message"], ...
                ColumnWidth={"auto", "auto", "auto", "auto"}, ...
                RowName={}, FontSize=13, ...
                CellSelectionCallback=@(~, event) ...
                    obj.selectRow(event), ...
                Tag="labkitSessionLogTable");
            if isprop(obj.EventTable, "SelectionType")
                obj.EventTable.SelectionType = "row";
            end
            obj.EventTable.Layout.Row = 4;

            obj.DetailArea = uitextarea(root, ...
                Editable="off", ...
                Value="Select an event to inspect complete structured details.", ...
                FontName="Consolas", ...
                Tag="labkitSessionLogDetail");
            obj.DetailArea.Layout.Row = 5;
            obj.Figure.SizeChangedFcn = ...
                @(~, ~) obj.resizeTableColumns();
            obj.resizeTableColumns();
        end

        function acceptRecord(obj, record)
            if obj.Closed
                return;
            end
            obj.Projection.append(record);
            obj.RefreshPending = true;
            if ~isempty(obj.RefreshPump) && isvalid(obj.RefreshPump) && ...
                    string(obj.RefreshPump.Running) == "off"
                start(obj.RefreshPump);
            end
        end

        function drainRefresh(obj)
            if obj.Closed || ~obj.RefreshPending
                return;
            end
            obj.RefreshPending = false;
            obj.refreshView(true);
        end

        function applyFilters(obj)
            obj.Projection.setFilters( ...
                Level=string(obj.LevelFilter.Value));
            obj.refreshView();
        end

        function toggleTraceCapture(obj)
            snapshot = obj.Runtime.diagnosticSnapshot();
            obj.Runtime.setTraceCapture(~snapshot.traceEnabled);
            obj.refresh();
        end

        function refreshView(obj, incremental)
            if nargin < 2
                incremental = false;
            end
            if obj.Closed || isempty(obj.Figure) || ~isvalid(obj.Figure)
                return;
            end
            projection = obj.Projection.view();
            if projection.traceEnabled
                obj.TraceButton.Text = "Disable TRACE";
            else
                obj.TraceButton.Text = "Enable TRACE";
            end
            rows = projection.rows;
            sequences = rows.Sequence.';
            previousCount = numel(obj.VisibleSequences);
            appended = incremental && ...
                numel(sequences) > previousCount && ...
                isequal(sequences(1:previousCount), obj.VisibleSequences);
            unchanged = incremental && ...
                isequal(sequences, obj.VisibleSequences);
            if appended
                added = rows(previousCount + 1:end, :);
                obj.EventTable.Data = [obj.EventTable.Data; added(:, 1:4)];
                obj.applyAppendedSeverityStyles(added.Level, previousCount);
            elseif ~unchanged
                obj.EventTable.Data = rows(:, 1:4);
                obj.applySeverityStyles(rows.Level);
            end
            obj.VisibleSequences = sequences;
            counts = projection.severityCounts;
            obj.SummaryLabel.Text = char(sprintf( ...
                "INFO %d   WARNING %d   ERROR %d   CRITICAL %d   Visible %d", ...
                counts.info, counts.warning, counts.error, ...
                counts.critical, height(rows)));
            if isempty(projection.notices)
                obj.NoticeLabel.Text = "Complete retained live view.";
                obj.NoticeLabel.FontColor = [0.1 0.45 0.15];
            else
                obj.NoticeLabel.Text = char(strjoin( ...
                    projection.notices, "  |  "));
                obj.NoticeLabel.FontColor = [0.55 0.28 0];
            end
            if appended || ~incremental
                obj.followLatest();
            end
        end

        function selectRow(obj, event)
            if isempty(event.Indices)
                return;
            end
            row = event.Indices(1, 1);
            if row < 1 || row > numel(obj.VisibleSequences)
                return;
            end
            record = obj.Projection.detail( ...
                obj.VisibleSequences(row));
            if isempty(record)
                return;
            end
            obj.DetailArea.Value = cellstr(detailLines(record));
            obj.CopyButton.Enable = "on";
        end

        function copyDetails(obj)
            try
                clipboard("copy", strjoin( ...
                    string(obj.DetailArea.Value), newline));
            catch
                obj.NoticeLabel.Text = ...
                    "Clipboard access is unavailable in this MATLAB session.";
                obj.NoticeLabel.FontColor = [0.55 0.28 0];
            end
        end

        function followLatest(obj)
            if isempty(obj.VisibleSequences)
                return;
            end
            try
                scroll(obj.EventTable, "bottom");
            catch
                % Older MATLAB releases retain native table navigation.
            end
        end

        function resizeTableColumns(obj)
            if isempty(obj.Figure) || ~isvalid(obj.Figure) || ...
                    isempty(obj.EventTable) || ~isvalid(obj.EventTable)
                return;
            end
            if ~isempty(obj.RootPanel) && isvalid(obj.RootPanel)
                obj.RootPanel.Position = ...
                    [1 1 obj.Figure.Position(3:4)];
            end
            available = max(620, obj.Figure.Position(3) - 42);
            fixed = 190 + 80 + 260;
            obj.EventTable.ColumnWidth = ...
                {190, 80, 260, max(220, available - fixed)};
        end

        function applySeverityStyles(obj, levels)
            try
                removeStyle(obj.EventTable);
                addSeverityStyle( ...
                    obj.EventTable, levels, "WARNING", ...
                    [1.00 0.96 0.78], [0.35 0.25 0.00]);
                addSeverityStyle( ...
                    obj.EventTable, levels, "ERROR", ...
                    [1.00 0.86 0.86], [0.55 0.00 0.00]);
                addSeverityStyle( ...
                    obj.EventTable, levels, "CRITICAL", ...
                    [0.55 0.05 0.05], [1.00 1.00 1.00]);
            catch
                % Severity text remains authoritative on older MATLAB releases.
            end
        end

        function applyAppendedSeverityStyles(obj, levels, rowOffset)
            try
                addSeverityStyle( ...
                    obj.EventTable, levels, "WARNING", ...
                    [1.00 0.96 0.78], [0.35 0.25 0.00], ...
                    rowOffset + find(string(levels) == "WARNING"));
                addSeverityStyle( ...
                    obj.EventTable, levels, "ERROR", ...
                    [1.00 0.86 0.86], [0.55 0.00 0.00], ...
                    rowOffset + find(string(levels) == "ERROR"));
                addSeverityStyle( ...
                    obj.EventTable, levels, "CRITICAL", ...
                    [0.55 0.05 0.05], [1.00 1.00 1.00], ...
                    rowOffset + find(string(levels) == "CRITICAL"));
            catch
                % Severity text remains authoritative on older MATLAB releases.
            end
        end
    end
end

function position = viewerPosition()
screen = double(get(groot, "ScreenSize"));
screenWidth = screen(3);
screenHeight = screen(4);
width = min(screenWidth, max(820, min(1280, screenWidth - 100)));
height = min(screenHeight, max(560, min(760, screenHeight - 140)));
x = max(screen(1), screen(1) + (screenWidth - width) / 2);
y = max(screen(2), screen(2) + (screenHeight - height) / 2);
position = round([x y width height]);
end

function value = detailLines(record)
attributes = "{}";
if ~isempty(fieldnames(record.attributes))
    attributes = string(jsonencode( ...
        record.attributes, PrettyPrint=true));
end
exception = record.exception;
stack = "";
if isstruct(exception) && isfield(exception, "stack") && ...
        ~isempty(exception.stack)
    stack = strjoin(string(exception.stack), newline);
end
value = [
    "Event: " + string(record.eventName)
    "Severity: " + string(record.severity) + ...
        "   Audience: " + string(record.audience)
    "Category: " + string(record.category)
    "Message: " + string(record.message)
    "Operation: " + string(record.operationId)
    "Parent: " + string(record.parentOperationId)
    "Root action: " + string(record.rootActionId)
    "Result: " + string(record.operationResult) + ...
        "   State: " + string(record.stateDisposition)
    "Duration (s): " + numericText(record.durationSeconds)
    "Exception: " + string(exception.identifier)
    "Exception message: " + string(exception.message)
    "Attributes:"
    attributes
    "Stack:"
    stack
    ];
end

function value = numericText(number)
if isempty(number)
    value = "";
else
    value = string(number);
end
end

function value = emptyRows()
value = table( ...
    strings(0, 1), strings(0, 1), ...
    strings(0, 1), strings(0, 1), ...
    VariableNames=["Time", "Level", "Area", "Message"]);
end

function addSeverityStyle( ...
        tableHandle, levels, severity, background, font, rows)
if nargin < 6
    rows = find(string(levels) == severity);
end
if isempty(rows)
    return;
end
style = uistyle( ...
    BackgroundColor=background, FontColor=font);
addStyle(tableHandle, style, "row", rows);
end
