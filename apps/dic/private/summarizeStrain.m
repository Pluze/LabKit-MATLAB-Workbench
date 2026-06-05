% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function T = summarizeStrain(strain, mask)
    exx = strain.exx(mask);
    eyy = strain.eyy(mask);
    metric = ["Mean"; "Std"; "Median"; "Min"; "Max"];
    exxValues = nanSafeStats(exx);
    eyyValues = nanSafeStats(eyy);
    T = table(metric, exxValues, eyyValues, ...
        'VariableNames', {'Metric', 'EXX', 'EYY'});
end
