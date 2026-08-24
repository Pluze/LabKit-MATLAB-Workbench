% Expected caller: labkit_FigureStudio_app. Inputs are public entrypoint
% varargin values. Output separates Studio-specific launch requests from
% ordinary LabKit dispatchRequest arguments. Side effects are none.
function [initialProject, dispatchArgs] = launchRequest(args)
    initialProject = [];
    dispatchArgs = args;
    if numel(args) >= 2 && isScalarText(args{1}) && string(args{1}) == "axes"
        ax = args{2};
        if isempty(ax) || ~isvalid(ax)
            error('labkit_FigureStudio_app:InvalidAxes', ...
                'Figure Studio axes launch requires a valid axes handle.');
        end
        drawnow nocallbacks
        initialProject = figure_studio.initialData();
        sourceStyle = figure_studio.sourceAxes.sourceStyle(ax);
        initialProject.inputs.sources = initialProject.inputs.sources([]);
        initialProject.annotations.embeddedPlot = ...
            figure_studio.resultFiles.extractAxesData(ax);
        initialProject.annotations.sourceDefaultStyle = sourceStyle;
        initialProject.annotations.transientSourceAxes = ax;
        publishedStyle = figure_studio.styleLibrary.styleForPreset( ...
            "Published figure");
        [publishedStyle, aspectPreset] = ...
            figure_studio.sourceAxes.applyStandardLayout( ...
            publishedStyle, initialProject.annotations.embeddedPlot);
        initialProject.parameters.preset = "Published figure";
        initialProject.parameters.style = publishedStyle;
        initialProject.parameters.gridChoice = onOff( ...
            publishedStyle.gridVisible);
        initialProject.parameters.boundaryChoice = onOff( ...
            publishedStyle.boundaryLines);
        initialProject.parameters.aspectPreset = aspectPreset;
        dispatchArgs = {};
    end
end

function value = onOff(tf)
    if tf
        value = "On";
    else
        value = "Off";
    end
end

function tf = isScalarText(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end
