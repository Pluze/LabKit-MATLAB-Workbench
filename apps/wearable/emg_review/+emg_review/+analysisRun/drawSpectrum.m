function drawSpectrum(axesById, model)
    axesList = [axesById.broadband axesById.lineBand];
    headings = ["Mean baseline and activity PSD", "60 Hz detail · shaded 58–62 Hz"];
    [~, ~, lineBand] = emg_review.analysisRun.bands();
    for k = 1:numel(axesList)
        ax = axesList(k);
        labkit.app.plot.clearAxes(ax, ResetScale=true);
        title(ax, headings(k));
        xlabel(ax, "Frequency (Hz)");
        ylabel(ax, "PSD (dB re 1 " + model.unit + "²/Hz)");
        grid(ax, 'on');
        if isempty(model.result)
            continue;
        end
        freq = model.result.frequency;
        if k == 2
            % Ten Hz on either side keeps narrow line power in context.
            band = mean(lineBand) + [-10 10];
            if freq(end) < band(1) || nnz(freq >= band(1) & freq <= band(2)) < 2
                title(ax, "60 Hz detail unavailable at this rate or window length");
                continue;
            end
            use = freq >= band(1) & freq <= band(2);
        else
            use = true(size(freq));
        end
        db = 10 * log10(max(model.result.density(use, :), realmin));
        hold(ax, 'on');
        baseline = plot(ax, freq(use), db(:, 1), 'Color', [0 0.40 0.65], ...
            'DisplayName', 'Baseline', 'LineWidth', 1.2);
        activity = plot(ax, freq(use), db(:, 2), 'Color', [0.70 0.29 0.04], ...
            'DisplayName', 'Activity', 'LineWidth', 1.2);
        if k == 2
            xlim(ax, band);
            height = ylim(ax);
            patch(ax, lineBand([1 2 2 1]), height([1 1 2 2]), [0.5 0.5 0.5], ...
                'FaceAlpha', .12, 'EdgeColor', 'none', 'HitTest', 'off', ...
                'PickableParts', 'none', 'HandleVisibility', 'off');
            ylim(ax, height);
        end
        legend(ax, [baseline activity], 'Location', 'best');
        hold(ax, 'off');
    end
end
