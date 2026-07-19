% App renderer; redraws one managed axes as a multi-group mean/SD comparison.
function drawComparison(axesById, model)
%DRAWCOMPARISON Draw grouped bars and first-group significance brackets.
%
% Expected caller: Runtime registered renderer. ax is a managed UI axes;
% model is prepared by resultPlot.present and contains copied group/result
% snapshots plus plot-only settings. The visual contract follows the selected
% reference style: white background, black boxed axes, pastel bars, SD error
% bars, no grid, and stacked first-versus-each significance brackets. Side
% effects are limited to redrawing ax.
ax = axesById.main;

    clearAxes(ax);
    if ~isstruct(model) || ~isscalar(model) || ...
            ~isfield(model, 'ready') || ~model.ready
        message = "No completed comparisons to plot.";
        if isstruct(model) && isfield(model, 'message')
            message = string(model.message);
        end
        showMessage(ax, message);
        return;
    end

    groups = model.groups;
    results = model.results;
    parameters = model.parameters;
    count = numel(groups);
    x = 1:count;
    colors = groupColors(count);
    plotChoices = ttest_wizard.resultPlot.choices();
    boxPlotLabel = plotChoices.types(2);
    hold(ax, 'on');

    plotType = string(parameters.type);
    drawGroups(ax, groups, model, parameters, colors, plotType, boxPlotLabel);
    if parameters.showPoints
        for groupIndex = 1:count
            values = double(groups(groupIndex).values(:));
            scatter(ax, groupIndex + deterministicJitter(numel(values)), ...
                values, 24, colors(groupIndex, :), 'filled', ...
                'MarkerEdgeColor', 'black', 'LineWidth', 0.5, ...
                'HitTest', 'off');
        end
    end

    values = double(vertcat(groups.values));
    if plotType == boxPlotLabel
        dataLow = min(values);
        dataTop = max(values);
    else
        dataLow = min([0; values]);
        dataTop = max(model.means);
        if parameters.showSummary
            dataTop = max(model.means + model.standardDeviations);
        end
    end
    if parameters.showPoints
        dataTop = max(dataTop, max(values));
    end
    span = max(dataTop - dataLow, max(1, abs(dataTop)));
    basePad = max(0.075 * span, eps);
    levelStep = max(0.12 * span, eps);
    capHeight = max(0.022 * span, eps);
    textPad = max(0.024 * span, eps);
    annotationTop = dataTop;
    if parameters.showPValue
        for resultIndex = 1:numel(results)
            if ~results(resultIndex).ok
                continue;
            end
            y = dataTop + basePad + (resultIndex - 1) * levelStep;
            annotationTop = max(annotationTop, y + capHeight + textPad);
        end
    end
    upperPad = 0.12 * span;
    if plotType ~= boxPlotLabel && dataLow >= 0
        lowerLimit = 0;
    else
        lowerLimit = dataLow - 0.08 * span;
    end
    upperLimit = annotationTop + upperPad;
    ax.YLim = [lowerLimit, upperLimit];
    ax.YTick = readableTicks(lowerLimit, upperLimit);
    if parameters.showPValue
        for resultIndex = 1:numel(results)
            if ~results(resultIndex).ok
                continue;
            end
            y = dataTop + basePad + (resultIndex - 1) * levelStep;
            drawSignificanceBracket(ax, 1, resultIndex + 1, y, ...
                capHeight, textPad, significanceText(results(resultIndex)));
        end
    end

    ax.XLim = [0.5 count + 0.5];
    ax.XTick = x;
    ax.XTickLabel = cellstr(string({groups.label}));
    ax.XTickLabelRotation = 0;
    ax.TickLabelInterpreter = 'none';
    ax.FontName = 'Helvetica';
    ax.FontSize = 14;
    ax.LineWidth = 1.2;
    ax.Color = 'white';
    ax.Box = 'on';
    ax.XGrid = 'off';
    ax.YGrid = 'off';
    ax.TickLength = [0.018 0.018];
    ax.YAxis.Exponent = 0;
    ylabel(ax, char(string(parameters.yLabel)), 'FontSize', 18);
    title(ax, char(string(parameters.title)));
    hold(ax, 'off');
end

function clearAxes(ax)
    delete(allchild(ax));
    cla(ax);
    ax.Visible = "on";
    ax.XLimMode = "auto";
    ax.YLimMode = "auto";
    ax.XScale = "linear";
    ax.YScale = "linear";
    ax.XTickMode = "auto";
    ax.YTickMode = "auto";
end

function showMessage(ax, message)
    text(ax, 0.5, 0.5, string(message), ...
        Units="normalized", HorizontalAlignment="center", ...
        VerticalAlignment="middle", Interpreter="none", HitTest="off");
    ax.XLim = [0 1];
    ax.YLim = [0 1];
    ax.XTick = [];
    ax.YTick = [];
    ax.Box = "off";
end

function drawGroups(ax, groups, model, parameters, colors, plotType, ...
        boxPlotLabel)
    count = numel(groups);
    x = 1:count;
    if plotType == boxPlotLabel
        for groupIndex = 1:count
            values = double(groups(groupIndex).values(:));
            boxchart(ax, repmat(groupIndex, numel(values), 1), values, ...
                'BoxWidth', 0.48, ...
                'BoxFaceColor', colors(groupIndex, :), ...
                'BoxFaceAlpha', 0.75, ...
                'BoxEdgeColor', 'black', ...
                'BoxMedianLineColor', 'black', ...
                'WhiskerLineColor', 'black', ...
                'MarkerColor', colors(groupIndex, :), ...
                'LineWidth', 1.1, ...
                'HitTest', 'off');
        end
        return;
    end

    bars = bar(ax, x, model.means, 0.48, ...
        'FaceColor', 'flat', 'EdgeColor', 'black', ...
        'LineWidth', 1.1, 'HitTest', 'off');
    bars.CData = colors;
    if parameters.showSummary
        errorbar(ax, x, model.means, model.standardDeviations, ...
            'LineStyle', 'none', 'Color', 'black', ...
            'LineWidth', 1.1, 'CapSize', 8, 'HitTest', 'off');
    end
end

function ticks = readableTicks(lowerLimit, upperLimit)
    span = upperLimit - lowerLimit;
    rawStep = span / 4;
    magnitude = 10 ^ floor(log10(rawStep));
    scaled = rawStep / magnitude;
    if scaled <= 1
        step = magnitude;
    elseif scaled <= 2
        step = 2 * magnitude;
    elseif scaled <= 2.5
        step = 2.5 * magnitude;
    elseif scaled <= 5
        step = 5 * magnitude;
    else
        step = 10 * magnitude;
    end
    first = ceil(lowerLimit / step) * step;
    last = floor(upperLimit / step) * step;
    ticks = first:step:last;
end

function colors = groupColors(count)
    palette = [ ...
        157 211 156
        245 195 138
        169 216 232
        255 248 154] / 255;
    colors = zeros(count, 3);
    for k = 1:count
        colors(k, :) = palette(mod(k - 1, size(palette, 1)) + 1, :);
    end
end

function offsets = deterministicJitter(count)
    if count <= 1
        offsets = zeros(count, 1);
    else
        phase = (1:count).';
        % Constant: golden-angle radians distribute deterministic marker jitter.
        offsets = 0.075 * sin(phase * 2.399963229728653);
        offsets = offsets - mean(offsets);
    end
end

function drawSignificanceBracket(ax, x1, x2, y, height, textPad, label)
    line(ax, [x1 x1 x2 x2], ...
        [y y + height y + height y], ...
        'Color', 'black', 'LineWidth', 1.2, 'HitTest', 'off');
    text(ax, (x1 + x2) / 2, y + height + textPad, label, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 16, 'FontWeight', 'bold', 'HitTest', 'off');
end

function textValue = significanceText(result)
    % Constant: conventional star thresholds for reported p-values.
    if result.pValue < 1e-4
        textValue = '****';
    elseif result.pValue < 1e-3
        textValue = '***';
    elseif result.pValue < 1e-2
        textValue = '**';
    elseif result.pValue < result.alpha
        textValue = '*';
    else
        textValue = 'NS';
    end
end
