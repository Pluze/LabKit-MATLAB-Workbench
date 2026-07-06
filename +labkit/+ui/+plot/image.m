function imageHandle = image(ui, id, imageData, varargin)
%IMAGE Draw image data into a UI 5 previewArea axes.
%
% App-facing contract:
%   h = labkit.ui.plot.image(ui, id, imageData, "title", titleText, ...
%       "axis", axisId, "options", opts)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - semantic id for a previewArea.
%   imageData - image matrix passed to the axes renderer.
%   title - optional axes title.
%   axis - optional named axes id.
%   options - optional struct passed to the existing image renderer. Supported
%       renderer fields include xData/yData image center coordinates,
%       clearAxes, hitTest, pickableParts, enableNavigation, and preserveView.
%
% Output:
%   imageHandle - graphics image object returned by the renderer.

    opts = parseOptions(varargin);
    control = resolvePlotControl(ui, id);
    ax = controlAxes(control, optionValue(opts, 'axis', ""));
    imageHandle = showImage(ax, imageData, ...
        fileContextTitle(ui, optionValue(opts, 'title', '')), ...
        optionValue(opts, 'options', struct()));
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
        error('labkit:ui:plot:InvalidOptions', ...
            'image options must be name/value pairs.');
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
