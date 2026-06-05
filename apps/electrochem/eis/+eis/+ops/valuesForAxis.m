% Expected caller: EIS app runner and unit tests. Inputs are an EIS item struct
% and axis label. Output is the selected numeric vector. No side effects.
function values = valuesForAxis(item, axisName)
    values = eis.core.dispatch("valuesForAxis", item, axisName);
end
