% Expected callers: CIC file-selection, project hydration, and export actions.
% Input is one DTA path plus durable parameters. Output is one decoded and
% analyzed chrono item plus the facade load status.
function [item, status] = loadItem(filepath, parameters)
    [item, status] = labkit.dta.loadFile(filepath, "chrono");
    if status.ok
        item.analysis = cic.analysisRun.computeCIC(item, ...
            cic.analysisRun.optionsFromParameters(parameters));
    end
end
