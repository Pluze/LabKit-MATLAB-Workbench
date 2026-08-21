classdef (Hidden, Sealed) BusyLifecycle < handle
    % Own delayed native busy presentation and non-reentrant input gating.
    % Caller: MatlabPlatformAdapter. The lifecycle retains only native window
    % state and invokes restoreView(snapshot,restoreValues) when work ends.

    properties (SetAccess = private)
        Active (1, 1) logical = false
    end

    properties (Access = private)
        Figure
        RestoreView
        InputHandles
        BaseWindowTitle (1, 1) string
        Visible (1, 1) logical = false
        Message (1, 1) string = ""
        RejectedInput (1, 1) logical = false
        Timer = []
        EnableHandles (1, :) cell = {}
        EnableValues (1, :) cell = {}
        PriorPointer (1, 1) string = "arrow"
    end

    methods
        function obj = BusyLifecycle( ...
                figureHandle, title, restoreView, inputHandles)
            if isempty(figureHandle) || ~isvalid(figureHandle) || ...
                    ~isa(restoreView, "function_handle") || ...
                    ~isscalar(restoreView) || ...
                    ~isa(inputHandles, "function_handle") || ...
                    ~isscalar(inputHandles)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Native busy lifecycle inputs are invalid.");
            end
            obj.Figure = figureHandle;
            obj.BaseWindowTitle = string(title);
            obj.RestoreView = restoreView;
            obj.InputHandles = inputHandles;
        end

        function setWindowTitle(obj, title)
            obj.BaseWindowTitle = string(title);
            if ~obj.Active && obj.hasFigure()
                obj.Figure.Name = char(obj.BaseWindowTitle);
            end
        end

        function begin(obj, message)
            if obj.Active || ~obj.hasFigure()
                return
            end
            message = strip(string(message));
            if strlength(message) == 0
                message = "Working";
            end
            obj.Active = true;
            obj.Visible = false;
            obj.Message = message;
            obj.RejectedInput = false;
            obj.PriorPointer = string(obj.Figure.Pointer);
            setappdata(obj.Figure, "labkitAppBusy", true);
            obj.Timer = timer( ...
                ExecutionMode="singleShot", StartDelay=0.5, ...
                BusyMode="drop", TimerFcn=@(~, ~) obj.show());
            start(obj.Timer);
        end

        function update(obj, message)
            if ~obj.Active
                return
            end
            message = strip(string(message));
            if strlength(message) > 0
                obj.Message = message;
            end
            if obj.Visible && obj.hasFigure()
                obj.Figure.Name = char(obj.busyWindowTitle());
                drawnow limitrate nocallbacks
            end
        end

        function accepted = acceptInput(obj)
            accepted = ~obj.Active;
            if ~accepted
                obj.RejectedInput = true;
            end
        end

        function finish(obj, view)
            if ~obj.Active
                return
            end
            wasVisible = obj.Visible;
            rejectedInput = obj.RejectedInput;
            obj.Active = false;
            obj.Visible = false;
            obj.RejectedInput = false;
            obj.cancelTimer();
            if ~obj.hasFigure()
                return
            end
            if wasVisible || rejectedInput
                obj.restoreControls();
                obj.RestoreView(view, rejectedInput);
            end
            if wasVisible
                obj.Figure.Pointer = char(obj.PriorPointer);
                obj.Figure.Name = char(obj.BaseWindowTitle);
            end
            if isappdata(obj.Figure, "labkitAppBusy")
                rmappdata(obj.Figure, "labkitAppBusy");
            end
            if wasVisible
                drawnow limitrate nocallbacks
            end
        end

        function close(obj)
            obj.Active = false;
            obj.Visible = false;
            obj.RejectedInput = false;
            obj.cancelTimer();
            obj.EnableHandles = {};
            obj.EnableValues = {};
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function show(obj)
            if ~obj.Active || obj.Visible || ~obj.hasFigure()
                return
            end
            obj.Visible = true;
            obj.Figure.Pointer = "watch";
            obj.Figure.Name = char(obj.busyWindowTitle());
            obj.disableControls();
            drawnow limitrate nocallbacks
        end

        function title = busyWindowTitle(obj)
            title = obj.BaseWindowTitle + ...
                " [Working: " + obj.Message + "]";
        end

        function disableControls(obj)
            handles = obj.InputHandles();
            if ~iscell(handles)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Native busy input handles must be a cell array.");
            end
            obj.EnableHandles = cell(1, numel(handles));
            obj.EnableValues = cell(1, numel(handles));
            for index = 1:numel(handles)
                handle = handles{index};
                if isempty(handle) || ~isvalid(handle) || ...
                        ~isprop(handle, "Enable")
                    continue
                end
                obj.EnableHandles{index} = handle;
                obj.EnableValues{index} = handle.Enable;
                handle.Enable = "off";
            end
        end

        function restoreControls(obj)
            for index = 1:numel(obj.EnableHandles)
                handle = obj.EnableHandles{index};
                if ~isempty(handle) && isvalid(handle) && ...
                        ~isempty(obj.EnableValues{index})
                    handle.Enable = obj.EnableValues{index};
                end
            end
            obj.EnableHandles = {};
            obj.EnableValues = {};
        end

        function cancelTimer(obj)
            timerValue = obj.Timer;
            obj.Timer = [];
            if isempty(timerValue) || ~isvalid(timerValue)
                return
            end
            stop(timerValue);
            delete(timerValue);
        end

        function tf = hasFigure(obj)
            tf = ~isempty(obj.Figure) && isvalid(obj.Figure);
        end
    end
end
