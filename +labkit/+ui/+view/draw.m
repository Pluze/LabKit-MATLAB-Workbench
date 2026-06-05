function varargout = draw(ax, action, varargin)
%DRAW Apply an app-neutral rendering action to axes.
%
% App-facing contract:
%   labkit.ui.view.draw(ax, "reset", titleText, resetScaleAndTicks)
%   hImage = labkit.ui.view.draw(ax, "image", imageData, titleText, opts)
%   info = labkit.ui.view.draw(ax, "xy", x, y, labels, opts)
%   labkit.ui.view.draw(ax, "clear")
%   labkit.ui.view.draw(ax, "popout")
%
% Inputs:
%   ax - target axes.
%   action - "reset", "image", "xy", "clear", or "popout".
%   varargin - action-specific payload described above.
%
% Outputs:
%   image returns the image graphics object. xy returns a status struct.
%   reset, clear, and popout mutate axes in place and return [] when captured.

    switch normalizeAction(action)
        case 'reset'
            titleText = positional(varargin, 1, '');
            resetScaleAndTicks = positional(varargin, 2, false);
            resetAxes(ax, titleText, resetScaleAndTicks);
            out = [];
        case 'image'
            imageData = positional(varargin, 1, []);
            titleText = positional(varargin, 2, '');
            opts = positional(varargin, 3, struct());
            out = showImage(ax, imageData, titleText, opts);
        case 'xy'
            x = positional(varargin, 1, []);
            y = positional(varargin, 2, []);
            labels = positional(varargin, 3, struct());
            opts = positional(varargin, 4, struct());
            out = plotXY(ax, x, y, labels, opts);
        case 'clear'
            clearAxes(ax);
            out = [];
        case 'popout'
            enablePopout(ax);
            out = [];
        otherwise
            error('labkit_ui:draw:UnknownAction', ...
                'Unknown LabKit view draw action "%s".', char(action));
    end

    if nargout > 0
        varargout{1} = out;
    end
end

function action = normalizeAction(action)
    action = lower(regexprep(char(string(action)), '[^a-zA-Z0-9]', ''));
    switch action
        case {'plot', 'plotxy'}
            action = 'xy';
        case {'imageaxes', 'showimage'}
            action = 'image';
        case {'resetaxes', 'hardreset'}
            action = 'reset';
        case {'clearaxes'}
            action = 'clear';
        case {'enablepopout', 'axespopout'}
            action = 'popout';
    end
end

function value = positional(args, index, defaultValue)
    value = defaultValue;
    if numel(args) >= index && ~isempty(args{index})
        value = args{index};
    end
end
