% Expected caller: CIC app plotting helpers. Inputs are an axes and CIC result
% struct. Side effects are limited to drawing baseline guides on the axes.

function addBaselineYLines(ax, A)
    if isfinite(A.Eipp)
        yline(ax, A.Eipp, '--', ...
            sprintf('Baseline(cath) = %.3f V [%s]', A.Eipp, shortBaselineSource(A.baselineCathSource)), ...
            'Color',[0.20 0.20 0.20], 'LabelHorizontalAlignment','right', 'LabelVerticalAlignment','bottom');
    end
    if isfinite(A.Eipp_gap)
        yline(ax, A.Eipp_gap, '--', ...
            sprintf('Baseline(anod) = %.3f V [%s]', A.Eipp_gap, shortBaselineSource(A.baselineAnodSource)), ...
            'Color',[0.40 0.40 0.40], 'LabelHorizontalAlignment','right', 'LabelVerticalAlignment','top');
    end
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
