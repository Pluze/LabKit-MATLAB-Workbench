% Expected caller: Figure Studio direct callbacks during synthetic-input generation and
% unit guardrails. Input is a LabKit debug context. Output is a deterministic
% synthetic FIG sample pack. Side effects: writes anonymous debug FIG files
% and records a session manifest when available.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write Figure Studio debug FIG files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    figPath = sampleContext.samplePath("figure_studio/source.fig");
    writeDebugFigure(figPath);

    project = figure_studio.projectSpec().Create();
    project.inputs.sources = sampleContext.sourceRecord( ...
        "figure1", "figure", figPath, true);
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-figure", InitialProject=project, ...
        Artifacts={sampleContext.artifact( ...
            "sourceFigure", "figure", figPath)});
end

function writeDebugFigure(filepath)
    fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
        'Position', [100 100 720 540]);
    cleaner = onCleanup(@() delete(fig));
    ax = axes('Parent', fig);
    x = linspace(0, 40, 80);
    hold(ax, 'on');
    plot(ax, x, 0.04 .* x, 'LineWidth', 3, 'DisplayName', '0%');
    plot(ax, x, 0.05 .* x, 'LineWidth', 3, 'DisplayName', '0.1%');
    xline(ax, 20, 'R', 'Color', [0.85 0.10 0.10], ...
        'LineStyle', '--', 'LineWidth', 1.5);
    hold(ax, 'off');
    ax.FontName = 'Arial';
    ax.FontSize = 36;
    ax.LineWidth = 3;
    ax.Box = 'on';
    xlabel(ax, 'Strain (%)');
    ylabel(ax, 'Stress (MPa)');
    title(ax, 'Debug Figure');
    legend(ax, 'Location', 'northwest', 'Box', 'off');
    savefig(fig, char(filepath));
end
