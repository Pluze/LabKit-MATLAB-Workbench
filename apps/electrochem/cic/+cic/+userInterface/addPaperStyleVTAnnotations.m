% Expected caller: CIC app plotting helpers. Inputs mirror the app-owned VT
% annotation helper. Side effects are limited to annotating the supplied axes.

function addPaperStyleVTAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX)
    % Constant: SI display conversions express pulse duration in ms and
    % interpulse duration in us while analysis remains in seconds.
    millisecondsPerSecond = 1e3;
    microsecondsPerSecond = 1e6;
    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.07*dy;
    yMid = yl(1) + 0.55*dy;
    yLow = yl(1) + 0.18*dy;

    if strcmp(xChoice,'Sample #')
        cOnX = interp1Safe(A.t, A.pt, A.t_conset);
        aOnX = interp1Safe(A.t, A.pt, A.t_aonset);
        cathBase1 = interp1Safe(A.t, A.pt, A.baselineCathWindow(1));
        cathBase2 = interp1Safe(A.t, A.pt, A.baselineCathWindow(2));
        anodBase1 = interp1Safe(A.t, A.pt, A.baselineAnodWindow(1));
        anodBase2 = interp1Safe(A.t, A.pt, A.baselineAnodWindow(2));
    else
        cOnX = A.t_conset;
        aOnX = A.t_aonset;
        cathBase1 = A.baselineCathWindow(1);
        cathBase2 = A.baselineCathWindow(2);
        anodBase1 = A.baselineAnodWindow(1);
        anodBase2 = A.baselineAnodWindow(2);
    end

    plot(ax, emcX, A.Emc, 'o', 'MarkerFaceColor',[0.1 0.7 0.1], 'MarkerEdgeColor','k', 'MarkerSize',7);
    plot(ax, emaX, A.Ema, 'o', 'MarkerFaceColor',[0.95 0.8 0.1], 'MarkerEdgeColor','k', 'MarkerSize',7);
    plot(ax, cOnX, A.Vc_on, 's', 'MarkerFaceColor',[0.2 0.6 1.0], 'MarkerEdgeColor','k', 'MarkerSize',6);
    plot(ax, aOnX, A.Va_on, 's', 'MarkerFaceColor',[1.0 0.6 0.2], 'MarkerEdgeColor','k', 'MarkerSize',6);

    if isfinite(A.Eipp)
        drawBaselineSegment(ax, cathBase1, cathBase2, A.Eipp, [0.25 0.25 0.25], ...
            sprintf('Baseline(cath) = %.3f V [%s]', A.Eipp, shortBaselineSource(A.baselineCathSource)), 'bottom');
    end
    if isfinite(A.Eipp_gap)
        drawBaselineSegment(ax, anodBase1, anodBase2, A.Eipp_gap, [0.45 0.45 0.45], ...
            sprintf('Baseline(anod) = %.3f V [%s]', A.Eipp_gap, shortBaselineSource(A.baselineAnodSource)), 'top');
    end

    if isfinite(A.Eipp) && isfinite(A.Vc_on)
        plot(ax, [cOnX cOnX], [A.Eipp A.Vc_on], '--', 'Color',[0.2 0.6 1.0], 'LineWidth',1.0);
        text(ax, cOnX, 0.5*(A.Eipp + A.Vc_on), sprintf(' Va(c)=%.3f V', A.Va_cath_mag), ...
            'Color',[0.15 0.45 0.8], 'VerticalAlignment','middle', 'HorizontalAlignment','left');
    end
    if isfinite(A.Eipp_gap) && isfinite(A.Va_on)
        plot(ax, [aOnX aOnX], [A.Eipp_gap A.Va_on], '--', 'Color',[0.95 0.55 0.2], 'LineWidth',1.0);
        text(ax, aOnX, 0.5*(A.Eipp_gap + A.Va_on), sprintf(' Va(a)=%.3f V', A.Va_anod_mag), ...
            'Color',[0.75 0.35 0.05], 'VerticalAlignment','middle', 'HorizontalAlignment','left');
    end

    drawExtremaLabel(ax, emcX, A.Emc, sprintf('Emc = %.4f V', A.Emc), ...
        [0.1 0.5 0.1], 'left', 0.04);
    drawExtremaLabel(ax, emaX, A.Ema, sprintf('Ema = %.4f V', A.Ema), ...
        [0.6 0.4 0], 'right', -0.04);

    drawDurationBracket(ax, cathStartX, cathEndX, yTop, sprintf('tc = %.3f ms', millisecondsPerSecond*A.tc_s));
    drawDurationBracket(ax, anodStartX, anodEndX, yTop - 0.06*dy, sprintf('ta = %.3f ms', millisecondsPerSecond*A.ta_s));
    if A.tip_s > 0 && anodStartX > cathEndX
        drawDurationBracket(ax, cathEndX, anodStartX, yLow, sprintf('tip = %.1f us', microsecondsPerSecond*A.tip_s));
    end
    yline(ax, yMid, ':', 'Color',[0.8 0.8 0.8], 'HandleVisibility','off');
end

function drawDurationBracket(ax, x1, x2, y, labelText)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1 || ~isfinite(y)
        return;
    end
    yl = ylim(ax);
    h = 0.025 * (yl(2) - yl(1));
    plot(ax, [x1 x2], [y y], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    plot(ax, [x1 x1], [y-h y+h], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    plot(ax, [x2 x2], [y-h y+h], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    text(ax, 0.5*(x1+x2), y + 1.4*h, labelText, 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'BackgroundColor','w', 'Margin',1);
end

function drawBaselineSegment(ax, x1, x2, y, color, labelText, verticalAlignment)
    if ~isfinite(y)
        return;
    end
    if isfinite(x1) && isfinite(x2) && x2 > x1
        xStart = x1;
        xEnd = x2;
    else
        xl = xlim(ax);
        xStart = xl(1) + 0.04 * (xl(2) - xl(1));
        xEnd = xStart + 0.18 * (xl(2) - xl(1));
    end
    plot(ax, [xStart xEnd], [y y], '--', 'Color', color, 'LineWidth',1.4, 'HandleVisibility','off');
    text(ax, xStart, y, [' ' labelText], 'Color', color, 'VerticalAlignment', verticalAlignment, ...
        'BackgroundColor','w', 'Margin',1, 'Interpreter','none');
end

function drawExtremaLabel(ax, x, y, labelText, color, side, yOffsetFraction)
    if ~isfinite(x) || ~isfinite(y)
        return;
    end
    if strcmp(side, 'right')
        alignment = 'left';
        xOffset = 0.025;
    else
        alignment = 'right';
        xOffset = -0.025;
    end
    xyText = labkit.ui.plot.offsetData(ax, [x y], [xOffset yOffsetFraction]);
    xyText = labkit.ui.plot.clampData(ax, xyText, "Padding", 0.05);
    text(ax, xyText(1), xyText(2), labelText, ...
        'HorizontalAlignment', alignment, ...
        'VerticalAlignment', 'middle', ...
        'Color', color, ...
        'BackgroundColor', 'w', ...
        'Margin', 2, ...
        'Interpreter', 'none', ...
        'HandleVisibility', 'off');
end

function s = shortBaselineSource(sourceLabel)
    switch sourceLabel
        case 'pre-pulse median'
            s = 'pre';
        case 'interpulse median'
            s = 'gap';
        case 'post-pulse median'
            s = 'post';
        case 'zero fallback'
            s = '0 V fallback';
        case 'cathodic baseline fallback'
            s = 'cath fallback';
        otherwise
            s = sourceLabel;
    end
end

function v = interp1Safe(x, y, xq)
    if numel(x) < 2 || any(~isfinite([x(:); y(:)]))
        v = NaN;
        return;
    end

    try
        v = interp1(x, y, xq, 'linear', 'extrap');
    catch
        idx = nearestIndex(x, xq);
        v = y(idx);
    end
end

function idx = nearestIndex(x, xq)
    [~, idx] = min(abs(x - xq));
end
