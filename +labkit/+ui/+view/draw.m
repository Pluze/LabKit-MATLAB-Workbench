function varargout = draw(ax, action, varargin)
%DRAW Apply an app-neutral rendering action to axes.
%
% App-facing contract:
%   labkit.ui.view.draw(ax, "reset", titleText, resetScaleAndTicks)
%   hImage = labkit.ui.view.draw(ax, "image", imageData, titleText, opts)
%   labkit.ui.view.draw(ax, "clear")
%   labkit.ui.view.draw(ax, "popout")
%
% Inputs:
%   ax - target axes.
%   action - "reset", "image", "clear", or "popout".
%   varargin - action-specific payload described above.
%
% Outputs:
%   image returns the image graphics object. reset, clear, and popout mutate
%   axes in place and return [] when captured.

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
end

function value = positional(args, index, defaultValue)
    value = defaultValue;
    if numel(args) >= index && ~isempty(args{index})
        value = args{index};
    end
end
