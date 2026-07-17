%CREATESESSION Rebuild transient CSC curves and active selection.
% Expected caller: Runtime V2 through csc.definition. Decoded DTA curves and
% file/curve selection remain outside the durable project.
function session = createSession(project)
    items = csc.sourceFiles.loadProjectItems(project.inputs.sources);
    currentIndex = 0;
    choices = csc.userInterface.analysisChoices();
    currentCurve = choices.empty;
    if ~isempty(items)
        currentIndex = 1;
        currentCurve = choices.allCycles;
    end
    session = struct( ...
        "selection", struct( ...
            "currentIndex", currentIndex, ...
            "currentCurve", currentCurve), ...
        "cache", struct("items", items));
end
