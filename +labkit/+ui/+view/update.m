function varargout = update(target, action, varargin)
%UPDATE Apply an app-neutral state update to an existing UI handle group.
%
% App-facing contract:
%   labkit.ui.view.update(textArea, "appendLog", message)
%   labkit.ui.view.update(listbox, "listItems", names)
%   [value, idx] = labkit.ui.view.update(listbox, "listSelection", names, preferred, opts)
%   labkit.ui.view.update(plotControls, "setPlotSelections", topSelection, bottomSelection)
%   labkit.ui.view.update(plotControls, "swapPlotSelections")
%
% Inputs:
%   target - MATLAB handle or LabKit component struct returned by panel().
%   action - state update action.
%   varargin - action-specific payload described above.
%
% Output:
%   listSelection returns the applied value and selected indices. Other
%   actions mutate target in place and return [] when captured.

    switch normalizeAction(action)
        case 'appendlog'
            appendLog(target, positional(varargin, 1, ''));
            out = {[]};
        case 'listitems'
            refreshListboxItems(target, positional(varargin, 1, {}));
            out = {[]};
        case 'listselection'
            names = positional(varargin, 1, {});
            preferredSelection = positional(varargin, 2, target.Value);
            opts = positional(varargin, 3, struct());
            [value, index] = refreshListboxSelection(target, names, preferredSelection, opts);
            out = {value, index};
        case 'setplotselections'
            topSelection = positional(varargin, 1, struct());
            bottomSelection = positional(varargin, 2, struct());
            setTopBottomPlotSelections(target.topX, target.topY, ...
                target.bottomX, target.bottomY, topSelection, bottomSelection);
            out = {[]};
        case 'swapplotselections'
            swapTopBottomPlotSelections(target.topX, target.topY, ...
                target.bottomX, target.bottomY);
            out = {[]};
        otherwise
            error('labkit_ui:update:UnknownAction', ...
                'Unknown LabKit view update action "%s".', char(action));
    end

    for k = 1:min(nargout, numel(out))
        varargout{k} = out{k};
    end
    for k = (numel(out) + 1):nargout
        varargout{k} = [];
    end
end

function action = normalizeAction(action)
    action = lower(regexprep(char(string(action)), '[^a-zA-Z0-9]', ''));
end

function value = positional(args, index, defaultValue)
    value = defaultValue;
    if numel(args) >= index && ~isempty(args{index})
        value = args{index};
    end
end
