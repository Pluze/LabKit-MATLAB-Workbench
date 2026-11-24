function drawWaveform(axesById, model)
    ax = axesById.main;
    labkit.app.plot.clearAxes(ax, ResetScale=true);
    title(ax, "Recording waveform");
    xlabel(ax, "File time (s)");
    ylabel(ax, model.unit);
    grid(ax, 'on');
    if isempty(model.preview.time)
        return;
    end
    title(ax, model.channel + " · " + model.band, 'Interpreter', 'none');
    hold(ax, 'on');
    plot(ax, model.preview.time, model.preview.values, 'Color', [.20 .23 .28], ...
        'DisplayName', 'EMG');
    yBounds = ylim(ax);
    if model.duration > 0
        xlim(ax, [0 model.duration]);
    end
    colors = [0 0.40 0.65; 0.70 0.29 0.04];
    roles = ["Baseline", "Activity"];
    for k = 1:size(model.pairs, 1)
        for role = 1:2
            left = model.pairs(k, role);
            right = min(model.duration, left + model.width);
            if right <= left || ~isfinite(left)
                continue;
            end
            color = colors(role, :);
            patch(ax, [left right right left], yBounds([1 1 2 2]), color, ...
                'FaceAlpha', .10 + .12 * (k == model.selected), 'EdgeColor', 'none', ...
                'HitTest', 'off', 'PickableParts', 'none', 'HandleVisibility', 'off');
            label = roles(role) + " " + string(k);
            if role == 2 && ~isempty(model.snr)
                if isfinite(model.snr(k))
                    label = label + sprintf(" · %.1f dB", model.snr(k));
                else
                    label = label + " · SNR undefined";
                end
            end
            labelY = yBounds(2) - (0.06 + 0.12*(role-1)) * diff(yBounds);
            text(ax, (left + right)/2, labelY, label, 'Color', color, ...
                'HorizontalAlignment', 'center', 'Clipping', 'on', ...
                'BackgroundColor', [1 1 1], 'Margin', 2, ...
                'HitTest', 'off', 'PickableParts', 'none');
        end
    end
    ylim(ax, yBounds);
    hold(ax, 'off');
end
