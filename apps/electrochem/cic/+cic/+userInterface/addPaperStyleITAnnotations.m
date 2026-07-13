% Expected caller: CIC app plotting helpers. Inputs mirror the app-owned IT
% annotation helper. Side effects are limited to annotating the supplied axes.

function addPaperStyleITAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX)
    % Constant: SI display conversions express current in mA, pulse duration
    % in ms, and interpulse duration in us while analysis remains in A/s.
    milliampsPerAmp = 1e3;
    millisecondsPerSecond = 1e3;
    microsecondsPerSecond = 1e6;
    plot(ax, emcX, interp1Safe(chooseX(A,xChoice), A.Im, emcX), 'o', 'MarkerFaceColor',[0.1 0.7 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);
    plot(ax, emaX, interp1Safe(chooseX(A,xChoice), A.Im, emaX), 'o', 'MarkerFaceColor',[0.95 0.8 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

    plot(ax, [cathStartX cathEndX], [A.Ic_est_A A.Ic_est_A], '--', 'Color',[0.1 0.45 0.8], 'LineWidth',1.3);
    plot(ax, [anodStartX anodEndX], [A.Ia_est_A A.Ia_est_A], '--', 'Color',[0.85 0.45 0.1], 'LineWidth',1.3);
    text(ax, cathEndX, A.Ic_est_A, sprintf('  ic = %.3f mA', milliampsPerAmp*A.Ic_est_A), 'Color',[0.1 0.35 0.75], 'VerticalAlignment','bottom');
    text(ax, anodEndX, A.Ia_est_A, sprintf('  ia = %.3f mA', milliampsPerAmp*A.Ia_est_A), 'Color',[0.7 0.32 0.05], 'VerticalAlignment','top');

    labelPulseCharge(ax, cathStartX, cathEndX, A.Qc_C, 'Qc');
    labelPulseCharge(ax, anodStartX, anodEndX, A.Qa_C, 'Qa');

    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.08*dy;
    yMid = yl(2) - 0.16*dy;
    drawDurationBracket(ax, cathStartX, cathEndX, yTop, sprintf('tc = %.3f ms', millisecondsPerSecond*A.tc_s));
    drawDurationBracket(ax, anodStartX, anodEndX, yTop, sprintf('ta = %.3f ms', millisecondsPerSecond*A.ta_s));
    if A.tip_s > 0 && anodStartX > cathEndX
        drawDurationBracket(ax, cathEndX, anodStartX, yMid, sprintf('tip = %.1f us', microsecondsPerSecond*A.tip_s));
    end
end

function labelPulseCharge(ax, x1, x2, Q, tagText)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    xm = 0.5 * (x1 + x2);
    yl = ylim(ax);
    y0 = yl(1) + 0.90 * (yl(2) - yl(1));
    text(ax, xm, y0, sprintf('%s = %.3e C', tagText, Q), ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'BackgroundColor','w','Margin',2);
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

function x = chooseX(A, xChoice)
    if strcmp(xChoice, 'Sample #')
        x = A.pt;
    else
        x = A.t;
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
