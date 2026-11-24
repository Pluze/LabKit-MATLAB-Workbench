function drawTimeFrequency(axesById, model)
    ax = axesById.main;
    colorbar(ax, "off");

    labkit.app.plot.clearAxes(ax, ResetScale=true);
    title(ax, "EMG spectrogram");
    xlabel(ax, "File time (s)");
    ylabel(ax, "Frequency (Hz)");
    if isempty(model.result)
        return;
    end
    data = model.result.spectrogram;
    powerDb = 10 * log10(max(data.density, realmin));
    times = data.time;
    if isscalar(times)
        times = times + [-0.5 0.5]*data.windowSeconds;
        powerDb = [powerDb powerDb];
    end
    hold(ax, 'on');
    imagesc(ax, times([1 end]), data.frequency([1 end]), powerDb);
    ax.YDir = 'normal';
    ylim(ax, data.frequency([1 end]));
    peak = max(powerDb, [], 'all');
    % Limit the displayed dynamic range while retaining absolute PSD color units.
    colorRangeDb = 60;
    clim(ax, [peak - colorRangeDb peak]);
    colorbar(ax);
    title(ax, [sprintf("EMG spectrogram · %.3g s Hann window", data.windowSeconds), ...
        "Color shows PSD (dB re 1 " + model.unit + "²/Hz)"]);
    hold(ax, 'off');
end
