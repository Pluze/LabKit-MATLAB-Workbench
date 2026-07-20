% App-owned implementation for focus_stack.resultFiles.exportSummary within the focus_stack product workflow.
function state = exportSummary(state, context)
%EXPORTSUMMARY Write the current fusion summary as CSV.
state = focus_stack.resultFiles.exportResult(state, "summary", context);
end
