% Expected caller: batch_crop UI refresh helpers. Inputs are one scalar
% condition and two candidate values. Output is trueValue when condition is
% true, otherwise falseValue. No state is read or changed.
function value = ternary(condition, trueValue, falseValue)
%TERNARY Select one of two UI values from a logical condition.

    if condition
        value = trueValue;
        return;
    end
    value = falseValue;
end
