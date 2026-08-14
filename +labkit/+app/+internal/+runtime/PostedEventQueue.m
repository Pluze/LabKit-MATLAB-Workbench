classdef (Hidden, Sealed) PostedEventQueue < handle
    %POSTEDEVENTQUEUE Coalesce and schedule App-neutral runtime updates.
    % Caller: RuntimeKernel. Event ids and fixed update callbacks are retained
    % until the MATLAB event loop drains them. Repeated ids replace the pending
    % callback, and close cancels all pending work without invoking App code.

    properties (Access = private)
        Dispatch = []
        EventIds (1, :) string = strings(1, 0)
        Updates (1, :) cell = {}
        Pump = []
        Draining (1, 1) logical = false
        Closed (1, 1) logical = false
    end

    methods
        function obj = PostedEventQueue(dispatch)
            if ~isa(dispatch, "function_handle") || ~isscalar(dispatch) || ...
                    nargin(dispatch) ~= 2 || nargout(dispatch) > 0
                error("labkit:app:runtime:InvariantFailure", ...
                    "Posted event dispatch must accept id/update and return no outputs.");
            end
            obj.Dispatch = dispatch;
            obj.Pump = timer( ...
                "ExecutionMode", "fixedSpacing", ...
                "Period", 0.01, ...
                "BusyMode", "drop", ...
                "TimerFcn", @(~, ~) obj.drain());
        end

        function post(obj, eventId, updateState)
            if obj.Closed
                return;
            end
            match = find(obj.EventIds == eventId, 1);
            if isempty(match)
                obj.EventIds(end + 1) = eventId;
                obj.Updates{end + 1} = updateState;
            else
                obj.Updates{match} = updateState;
            end
            if string(obj.Pump.Running) == "off"
                start(obj.Pump);
            end
        end

        function drain(obj)
            if obj.Closed || obj.Draining || isempty(obj.EventIds)
                obj.stopIfEmpty();
                return;
            end
            obj.Draining = true;
            cleanup = onCleanup(@() obj.finishDrain());
            eventIds = obj.EventIds;
            updates = obj.Updates;
            obj.EventIds = strings(1, 0);
            obj.Updates = {};
            for index = 1:numel(eventIds)
                obj.Dispatch(eventIds(index), updates{index});
            end
            clear cleanup
        end

        function close(obj)
            if obj.Closed
                return;
            end
            obj.Closed = true;
            obj.EventIds = strings(1, 0);
            obj.Updates = {};
            pump = obj.Pump;
            obj.Pump = [];
            if ~isempty(pump) && isvalid(pump)
                stop(pump);
                delete(pump);
            end
            obj.Dispatch = @(~, ~) [];
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function finishDrain(obj)
            obj.Draining = false;
            obj.stopIfEmpty();
        end

        function stopIfEmpty(obj)
            if ~isempty(obj.EventIds) || isempty(obj.Pump) || ...
                    ~isvalid(obj.Pump) || string(obj.Pump.Running) == "off"
                return;
            end
            stop(obj.Pump);
        end
    end
end
