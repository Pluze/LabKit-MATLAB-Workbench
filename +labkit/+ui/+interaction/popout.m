function newFig = popout(srcAx, varargin)
%POPOUT Copy a UI axes into an editable MATLAB figure.
%
% App-facing contract:
%   newFig = labkit.ui.interaction.popout(srcAx)
%   newFig = labkit.ui.interaction.popout(srcAx, "Toolbar", true)
%   newFig = labkit.ui.interaction.popout(srcAx, "Title", titleText)
%
% Inputs:
%   srcAx - source UI axes or axes handle.
%   Toolbar - optional logical scalar. When true, the copied figure gets
%       LabKit publication-cleanup tools for copied-figure styling, copy,
%       export, visible-data export, and recreate-script generation. Default
%       is true.
%   Title - optional scalar text used for the standalone figure name.
%
% Output:
%   newFig - standalone MATLAB figure containing copied axes content. Plot
%       axes are freely resizable; image axes preserve data aspect ratio.

    opts = parseOptions(varargin);
    if isempty(srcAx) || ~isvalid(srcAx)
        error('labkit:ui:InvalidAxes', 'Source axes is not valid.');
    end

    titleText = string(opts.Title);
    if strlength(titleText) == 0
        titleText = axisLabelText(srcAx.Title);
        if strlength(titleText) == 0
            titleText = "LabKit Plot";
        end
    end

    figArgs = {'Name', char(titleText), 'Color', 'w'};
    if guiTestMode() == "hidden"
        figArgs = [figArgs, {'Visible', 'off'}];
    end
    newFig = figure(figArgs{:});
    applyGuiTestMode(newFig);
    dstAx = axes('Parent', newFig);
    copyAxesState(srcAx, dstAx);

    children = flipud(srcAx.Children(:));
    if ~isempty(children)
        copyobj(children, dstAx);
    end
    applyAxesState(srcAx, dstAx);
    if opts.Toolbar
        createPopoutToolbar(newFig, dstAx);
    end
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:InvalidPopoutOptions', ...
            'popout options must be name-value pairs.');
    end
    opts = struct('Toolbar', true, 'Title', "");
    for k = 1:2:numel(args)
        name = string(args{k});
        switch lower(name)
            case "toolbar"
                opts.Toolbar = logicalScalar(args{k + 1}, "Toolbar");
            case "title"
                opts.Title = string(args{k + 1});
                if ~isscalar(opts.Title)
                    error('labkit:ui:InvalidPopoutOptions', ...
                        'Title must be scalar text.');
                end
            otherwise
                error('labkit:ui:InvalidPopoutOptions', ...
                    'Unsupported popout option "%s".', char(name));
        end
    end
end

function value = logicalScalar(value, name)
    if ~(islogical(value) || isnumeric(value)) || ~isscalar(value)
        error('labkit:ui:InvalidPopoutOptions', ...
            '%s must be a logical scalar.', name);
    end
    value = logical(value);
end

function mode = guiTestMode()
    mode = lower(strtrim(string(getenv('LABKIT_GUI_TEST_MODE'))));
    if ~any(mode == ["hidden", "minimized"])
        mode = "visible";
    end
end

function applyGuiTestMode(fig)
    if guiTestMode() == "minimized" && isprop(fig, 'WindowState')
        try
            fig.WindowState = 'minimized';
        catch
        end
    end
end

function copyAxesState(srcAx, dstAx)
    props = {'XScale','YScale','ZScale','XDir','YDir','ZDir', ...
        'XLim','YLim','ZLim','CLim', ...
        'Layer','Box','XGrid','YGrid','ZGrid','Color','XColor','YColor','ZColor', ...
        'LineWidth','FontName','FontSize','FontWeight','FontAngle'};
    for k = 1:numel(props)
        try
            dstAx.(props{k}) = srcAx.(props{k});
        catch
        end
    end
    try
        colormap(dstAx, colormap(srcAx));
    catch
    end
end

function applyAxesState(srcAx, dstAx)
    title(dstAx, axisLabelText(srcAx.Title));
    xlabel(dstAx, axisLabelText(srcAx.XLabel));
    ylabel(dstAx, axisLabelText(srcAx.YLabel));
    zlabel(dstAx, axisLabelText(srcAx.ZLabel));

    try
        dstAx.XLimMode = srcAx.XLimMode;
        dstAx.YLimMode = srcAx.YLimMode;
        dstAx.ZLimMode = srcAx.ZLimMode;
        dstAx.CLimMode = srcAx.CLimMode;
    catch
    end
    applyAspectRatio(srcAx, dstAx);
    addLegendIfNeeded(dstAx);
end

function applyAspectRatio(srcAx, dstAx)
    if hasImageContent(srcAx)
        lockImageAspectRatio(srcAx, dstAx);
    else
        unlockAspectRatio(dstAx);
    end
end

function unlockAspectRatio(ax)
    try
        ax.DataAspectRatioMode = 'auto';
        ax.PlotBoxAspectRatioMode = 'auto';
        ax.ActivePositionProperty = 'outerposition';
    catch
    end
end

function lockImageAspectRatio(srcAx, dstAx)
    try
        dstAx.DataAspectRatio = srcAx.DataAspectRatio;
        dstAx.DataAspectRatioMode = 'manual';
        dstAx.PlotBoxAspectRatioMode = 'auto';
        dstAx.ActivePositionProperty = 'outerposition';
    catch
        axis(dstAx, 'image');
    end
end

function tf = hasImageContent(ax)
    children = ax.Children;
    tf = false;
    for k = 1:numel(children)
        if isgraphics(children(k), 'image')
            tf = true;
            return;
        end
    end
end

function text = axisLabelText(labelHandle)
    value = labelHandle.String;
    if iscell(value)
        text = string(strjoin(value, newline));
    else
        text = string(value);
    end
end

function addLegendIfNeeded(ax)
    children = ax.Children;
    names = strings(0, 1);
    for k = 1:numel(children)
        if isprop(children(k), 'DisplayName')
            name = string(children(k).DisplayName);
            if strlength(name) > 0 && ~startsWith(name, "_")
                names(end+1, 1) = name;
            end
        end
    end
    if ~isempty(names)
        legend(ax, 'show', 'Interpreter', 'none');
    end
end
