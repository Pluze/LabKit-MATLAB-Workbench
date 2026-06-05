% App-owned focus-stack conditional helper. Expected caller:
% labkit_FocusStack_app UI state refresh. Inputs are condition and two values.
% Output is the selected value. This helper has no side effects.
function value = ternary(condition, trueValue, falseValue)
%TERNARY Return trueValue or falseValue from a scalar condition.

    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
