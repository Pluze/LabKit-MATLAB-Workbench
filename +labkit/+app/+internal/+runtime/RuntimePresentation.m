% Derive the complete default Snapshot from compiled layout and App state.
% Expected caller: RuntimeKernel before overlaying the App-owned Snapshot.
% Inputs are a compiled platform plan, scalar application state, live
% source store, and current status. The method returns a new immutable Snapshot
% and does not create or mutate native MATLAB graphics.
classdef (Sealed, Hidden) RuntimePresentation
    methods (Static)
        function view = fromState( ...
                plan, state, sourcePathsForRole, currentStatus)
            view = labkit.app.view.Snapshot();
            for k = 1:numel(plan.Nodes)
                node = plan.Nodes(k);
                if isempty(node.Capabilities)
                    continue;
                end
                config = node.Configuration;
                switch node.Kind
                    case "button"
                        view = view.enabled(node.Id, config.Enabled);
                    case "field"
                        value = ...
                            labkit.app.internal.runtime.RuntimePresentation.neutralValue( ...
                            config.Value, config.Kind, config.Choices);
                        if strlength(config.Bind) > 0
                            value = labkit.app.internal.runtime.RuntimeStatePath.read( ...
                                state, config.Bind);
                        end
                        view = view.value(node.Id, value);
                        if ~isempty(config.Choices)
                            view = view.choices(node.Id, config.Choices);
                        end
                        if ~isempty(config.Limits)
                            view = view.limits(node.Id, config.Limits);
                        end
                        view = view.enabled(node.Id, config.Enabled);
                    case "rangeField"
                        limits = config.Limits;
                        if isempty(limits)
                            limits = [0 1];
                        end
                        value = config.Value;
                        if isempty(value)
                            value = limits;
                        end
                        if strlength(config.Bind) > 0
                            value = labkit.app.internal.runtime.RuntimeStatePath.read( ...
                                state, config.Bind);
                        end
                        view = view.value(node.Id, value);
                        view = view.limits(node.Id, limits);
                        view = view.enabled(node.Id, config.Enabled);
                    case "slider"
                        value = config.Value;
                        if strlength(config.Bind) > 0
                            value = labkit.app.internal.runtime.RuntimeStatePath.read( ...
                                state, config.Bind);
                        end
                        view = view.value(node.Id, value);
                        if ~isempty(config.Limits)
                            view = view.limits(node.Id, config.Limits);
                        end
                        view = view.enabled(node.Id, config.Enabled);
                    case "fileList"
                        paths = strings(0, 1);
                        if strlength(config.Bind) > 0
                            sourceRecords = ...
                                labkit.app.internal.runtime.RuntimeStatePath.read( ...
                                state, config.Bind);
                            paths = sourcePathsForRole( ...
                                sourceRecords, config.SourceRole);
                        end
                        view = view.filePaths(node.Id, paths);
                        if strlength(config.SelectionBind) > 0
                            selection = ...
                                labkit.app.internal.runtime.RuntimeStatePath.read( ...
                                state, config.SelectionBind);
                            view = view.listSelection(node.Id, selection);
                        end
                    case "plotArea"
                        view = view.visible(node.Id, true);
                    case "dataTable"
                        view = view.tableData(node.Id, cell(0, 0), ...
                            Columns=config.Columns, ...
                            RowNames=config.RowNames, ...
                            ColumnEditable=config.ColumnEditable);
                    case "statusPanel"
                        status = config.Text;
                        if isempty(status) && strlength(currentStatus) > 0
                            status = currentStatus;
                        end
                        view = view.text(node.Id, join(status, newline));
                    case "workspacePage"
                        view = view.workspacePage(node.Id);
                    otherwise
                        error("labkit:app:runtime:InvariantFailure", ...
                            "No default presentation for Layout kind %s.", ...
                            node.Kind);
                end
            end
        end
    end

    methods (Static, Access = private)
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
    end
end
