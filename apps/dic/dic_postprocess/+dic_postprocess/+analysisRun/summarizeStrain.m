function T = summarizeStrain(strain, mask)
%SUMMARIZESTRAIN Summarize finite EXX and EYY values inside a mask.
%
% Usage:
%   T = dic_postprocess.analysisRun.summarizeStrain(strain, mask)
%
% Inputs:
%   strain - Scalar struct with numeric exx and eyy arrays of the same size.
%   mask - Logical array matching exx and eyy. true entries select samples for
%       both components.
%
% Outputs:
%   T - Five-row table. Metric contains "Mean", "Std", "Median", "Min", and
%       "Max"; EXX and EYY contain the corresponding statistics.
%
% Description:
%   Nonfinite values are removed independently from each selected component.
%   Std uses MATLAB's default sample standard deviation. When a component has no
%   finite selected values, all five values for that component are NaN.
%
% Example:
%   strain = struct("exx", [1 2; NaN 4], "eyy", [2 4; 6 Inf]);
%   T = dic_postprocess.analysisRun.summarizeStrain( ...
%       strain, true(2));
%   assert(T.EXX(T.Metric == "Mean") == 7/3)
%   assert(T.EYY(T.Metric == "Max") == 6)
%
% See also dic_postprocess.analysisRun.prepareOutputs
    exx = strain.exx(mask);
    eyy = strain.eyy(mask);
    metric = ["Mean"; "Std"; "Median"; "Min"; "Max"];
    exxValues = dic_postprocess.analysisRun.nanSafeStats(exx);
    eyyValues = dic_postprocess.analysisRun.nanSafeStats(eyy);
    T = table(metric, exxValues, eyyValues, ...
        'VariableNames', {'Metric', 'EXX', 'EYY'});
end
