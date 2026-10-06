function state = exportFocusMap(state, context)
%EXPORTFOCUSMAP Write the current focus-depth index map as PNG.
state = focus_stack.resultFiles.exportResult(state, "focus-map", context);
end
