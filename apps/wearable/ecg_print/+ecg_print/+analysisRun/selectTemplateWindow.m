function applicationState = selectTemplateWindow(applicationState, value, ~)
%SELECTTEMPLATEWINDOW Commit the window selected from the current result list.
choices = ecg_print.analysisRun.templateWindowChoices(applicationState.session.cache.ecgNext);
index = find(choices==string(value),1);
if isempty(index)
    error('ecg_print:InvalidTemplateWindow','Select an available extraction window.');
end
applicationState.session.templateWindow = index;
end
