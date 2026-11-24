function drawSpectrum(axesById, model)
    ax = axesById.main;
    labkit.app.plot.clearAxes(ax, ResetScale=true);
    title(ax, "Mean baseline and activity PSD");
    xlabel(ax, "Frequency (Hz)");
    ylabel(ax, "PSD (dB re 1 " + model.unit + "²/Hz)");
    grid(ax, 'on');
    if isempty(model.result)
        return;
    end
    freq = model.result.frequency;
    use = freq >= model.frequencyLimits(1) & freq <= model.frequencyLimits(2);
    xlim(ax, model.frequencyLimits);
    if ~any(use)
        title(ax, "Increase the window duration to resolve this frequency range");
        return;
    end
    db = 10 * log10(max(model.result.density(use, :), realmin));
    hold(ax, 'on');
    baseline = plot(ax, freq(use), db(:, 1), 'Color', [0 0.40 0.65], ...
        'DisplayName', 'Baseline', 'LineWidth', 1.2);
    activity = plot(ax, freq(use), db(:, 2), 'Color', [0.70 0.29 0.04], ...
        'DisplayName', 'Activity', 'LineWidth', 1.2);
    legend(ax, [baseline activity], 'Location', 'best');
    hold(ax, 'off');
end
