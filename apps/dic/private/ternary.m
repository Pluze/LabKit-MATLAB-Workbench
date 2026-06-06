% DIC family private helper. Expected caller: remaining DIC postprocess app code.
% Inputs are a condition and display alternatives. Output is the selected text.
% Side effects: none.
function txt = ternary(cond, trueText, falseText)
    if cond
        txt = trueText;
    else
        txt = falseText;
    end
end
