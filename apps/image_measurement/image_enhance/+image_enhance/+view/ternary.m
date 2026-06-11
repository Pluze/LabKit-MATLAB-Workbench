% Expected caller: labkit_ImageEnhance_app UI state updates. Return trueValue
% when condition is true, otherwise falseValue.
function value = ternary(condition, trueValue, falseValue)

    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
