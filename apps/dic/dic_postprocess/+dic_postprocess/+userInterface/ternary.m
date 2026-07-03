% DIC Postprocess view helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are a condition and display alternatives. Output is the selected text.
% Side effects: none.
function txt = ternary(cond, trueText, falseText)
    if cond
        txt = trueText;
    else
        txt = falseText;
    end
end
