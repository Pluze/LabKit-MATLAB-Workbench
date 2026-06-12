function imageHandle = drawImage(ui, id, imageData, varargin)
%DRAWIMAGE Draw image data into a UI 2.0 previewArea axes.
%
% App-facing contract:
%   h = labkit.ui.view.drawImage(ui, id, imageData, "title", titleText, ...
%       "axis", axisId, "options", opts)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - semantic id for a previewArea.
%   imageData - image matrix passed to the axes renderer.
%   title - optional axes title.
%   axis - optional named axes id.
%   options - optional struct passed to the existing image renderer.
%
% Output:
%   imageHandle - graphics image object returned by the renderer.

    opts = parseOptions(varargin);
    control = resolveControl(ui, id);
    ax = controlAxes(control, optionValue(opts, 'axis', ""));
    imageHandle = showImage(ax, imageData, ...
        optionValue(opts, 'title', ''), optionValue(opts, 'options', struct()));
end

function opts = parseOptions(args)
    opts = struct();
    if isempty(args)
        return;
    end
    if numel(args) == 1 && (ischar(args{1}) || isstring(args{1}))
        opts.title = char(string(args{1}));
        return;
    end
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:view:InvalidOptions', ...
            'drawImage options must be name/value pairs.');
    end
    for k = 1:2:numel(args)
        opts.(char(string(args{k}))) = args{k + 1};
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
