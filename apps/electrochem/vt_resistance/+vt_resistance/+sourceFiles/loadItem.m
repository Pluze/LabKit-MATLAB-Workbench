% Expected callers: VT Resistance file-selection, project hydration, and
% export actions. Input is one DTA path plus durable parameters. Output is
% one decoded and analyzed chrono item plus the facade load status.
function [item, status] = loadItem(filepath, parameters)
    [item, status] = labkit.dta.loadFile(filepath, "chrono");
    if status.ok
        item.analysis = vt_resistance.analysisRun.computeResistance(item, ...
            vt_resistance.analysisRun.optionsFromParameters(parameters));
    end
end
