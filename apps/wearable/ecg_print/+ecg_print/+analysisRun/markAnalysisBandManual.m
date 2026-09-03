% Expected caller: main bandpass control value-change signals.
function applicationState = markAnalysisBandManual( ...
        applicationState, ~, ~)
%MARKANALYSISBANDMANUAL Preserve user-selected cutoffs across source changes.
applicationState.project.parameters.analysisBandAutomatic = false;
end
