% Private UI app helper. Expected caller: readonly field adapters. Inputs are
% a text-bearing MATLAB UI handle and a new value. Output is none. Side
% effects update the visible text and reapply default text fitting.
function setReadonlyText(control, value)
    text = char(string(value));
    if isprop(control, 'Text')
        if strcmp(control.Text, text)
            return;
        end
        control.Text = text;
    elseif isprop(control, 'Value')
        currentText = readonlyValueText(control.Value);
        if strcmp(currentText, text)
            return;
        end
        control.Value = text;
    end
    applyTextFit(control);
end

function text = readonlyValueText(value)
    if iscell(value)
        text = char(join(string(value(:)), newline));
    else
        text = char(join(string(value(:)), newline));
    end
end
