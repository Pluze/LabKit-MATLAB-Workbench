function varargout = runBusy(fig, workFcn, opts)
%RUNBUSY Run synchronous GUI work with busy feedback.
%
% Usage:
%   labkit.ui.app.runBusy(fig, @() refreshResults(), opts);
%   result = labkit.ui.app.runBusy(fig, @() computeResult(), opts);
%
% Inputs:
%   fig - owning uifigure or figure. Empty or invalid figures are accepted;
%       control disabling still runs for valid controls in opts.controls.
%   workFcn - scalar function handle to run synchronously.
%   opts - optional struct.
%
% Options:
%   controls - UI component handle array or cell array. Valid components
%       with an Enable property are disabled while workFcn runs and restored
%       afterward. Default [].
%   title - progress dialog title, default "Working".
%   message - progress dialog message, default "Please wait...".
%   showDialog - logical, default true. Shows an indeterminate progress
%       dialog when fig is valid and uiprogressdlg is available.
%   indeterminate - logical, default true. Uses an indeterminate progress
%       dialog. When false, opts.value is used as the initial value.
%   value - scalar in [0, 1], default 0.05, used only when indeterminate is
%       false.
%   pointer - figure pointer while work runs, default "watch".
%
% Outputs:
%   varargout - outputs returned by workFcn. When no outputs are requested,
%       workFcn is called for side effects only.
%
% Notes:
%   This helper is intended for long, synchronous callbacks. If the callback
%   permanently changes control enable states, refresh those states after
%   runBusy returns so the cleanup restore does not preserve stale
%   pre-run values.

    if nargin < 3
        opts = struct();
    end
    if ~isa(workFcn, 'function_handle')
        error('labkit:ui:runBusy:InvalidCallback', ...
            'workFcn must be a function handle.');
    end

    validFig = isLiveHandle(fig);
    controlState = disableControls(optionValue(opts, 'controls', []));
    [oldPointer, pointerChanged] = setBusyPointer( ...
        fig, validFig, optionValue(opts, 'pointer', 'watch'));
    dlg = createProgressDialog(fig, validFig, opts);
    cleanupObj = onCleanup(@() restoreBusyState( ...
        controlState, fig, validFig, oldPointer, pointerChanged, dlg));

    drawnow;
    if nargout == 0
        workFcn();
    else
        [varargout{1:nargout}] = workFcn();
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function controlState = disableControls(controls)
    handles = normalizeControls(controls);
    controlState = struct('handle', {}, 'enable', {});
    for k = 1:numel(handles)
        h = handles{k};
        if ~isLiveHandle(h) || ~isprop(h, 'Enable')
            continue;
        end
        controlState(end+1) = struct( ...
            'handle', h, ...
            'enable', h.Enable);
        h.Enable = 'off';
    end
end

function handles = normalizeControls(controls)
    if isempty(controls)
        handles = {};
    elseif iscell(controls)
        handles = controls(:);
    else
        try
            handles = num2cell(controls(:));
        catch
            handles = {controls};
        end
    end
end

function [oldPointer, pointerChanged] = setBusyPointer(fig, validFig, pointer)
    oldPointer = '';
    pointerChanged = false;
    if ~validFig || ~isprop(fig, 'Pointer')
        return;
    end

    oldPointer = fig.Pointer;
    try
        fig.Pointer = char(pointer);
        pointerChanged = true;
    catch
        pointerChanged = false;
    end
end

function dlg = createProgressDialog(fig, validFig, opts)
    dlg = [];
    if ~validFig || ~optionValue(opts, 'showDialog', true)
        return;
    end

    titleText = char(optionValue(opts, 'title', 'Working'));
    messageText = char(optionValue(opts, 'message', 'Please wait...'));
    indeterminate = logical(optionValue(opts, 'indeterminate', true));
    try
        if indeterminate
            dlg = uiprogressdlg(fig, ...
                'Title', titleText, ...
                'Message', messageText, ...
                'Indeterminate', 'on');
        else
            dlg = uiprogressdlg(fig, ...
                'Title', titleText, ...
                'Message', messageText, ...
                'Value', optionValue(opts, 'value', 0.05));
        end
    catch
        dlg = [];
    end
end

function restoreBusyState(controlState, fig, validFig, oldPointer, pointerChanged, dlg)
    if ~isempty(dlg) && isLiveHandle(dlg)
        try
            close(dlg);
        catch
        end
    end

    if validFig && pointerChanged && isLiveHandle(fig) && isprop(fig, 'Pointer')
        try
            fig.Pointer = oldPointer;
        catch
        end
    end

    for k = numel(controlState):-1:1
        h = controlState(k).handle;
        if isLiveHandle(h) && isprop(h, 'Enable')
            try
                h.Enable = controlState(k).enable;
            catch
            end
        end
    end
    drawnow;
end

function tf = isLiveHandle(h)
    tf = ~isempty(h);
    if ~tf
        return;
    end
    try
        tf = all(isvalid(h));
    catch
        tf = false;
    end
end
