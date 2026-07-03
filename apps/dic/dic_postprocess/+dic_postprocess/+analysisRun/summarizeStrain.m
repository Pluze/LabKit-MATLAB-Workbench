% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are strain struct and logical summary mask. Output is ROI strain
% summary table with Metric, EXX, and EYY columns. Side effects: none.
function T = summarizeStrain(strain, mask)
    exx = strain.exx(mask);
    eyy = strain.eyy(mask);
    metric = ["Mean"; "Std"; "Median"; "Min"; "Max"];
    exxValues = dic_postprocess.analysisRun.nanSafeStats(exx);
    eyyValues = dic_postprocess.analysisRun.nanSafeStats(eyy);
    T = table(metric, exxValues, eyyValues, ...
        'VariableNames', {'Metric', 'EXX', 'EYY'});
end
