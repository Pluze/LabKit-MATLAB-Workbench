% App-owned implementation for focus_stack.resultFiles.exportFused within the focus_stack product workflow.
function state = exportFused(state, context)
%EXPORTFUSED Write the current fused image as a user-selected PNG.
state = focus_stack.resultFiles.exportResult(state, "fused", context);
end
