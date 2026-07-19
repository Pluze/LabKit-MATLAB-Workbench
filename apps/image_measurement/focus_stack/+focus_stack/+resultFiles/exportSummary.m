function state = exportSummary(state, context)
%EXPORTSUMMARY Write the current fusion summary as CSV.
if ~state.session.cache.result.ok
    context.alert("Run focus stack before exporting results.", "No result"); return
end
choice = context.chooseOutputFile(["*.csv", "CSV files (*.csv)"], pwd);
if choice.Cancelled, return, end
paths = context.resolveSourcePaths(state.project.inputs.sources);
writetable(focus_stack.resultFiles.buildSummaryTable(state.session.cache.result, paths), choice.Value);
context.appendStatus("Exported summary: " + string(choice.Value));
end
