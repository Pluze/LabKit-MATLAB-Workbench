% Private UI app helper. Expected caller: readonly field adapters. Input is a
% MATLAB UI handle with a Value property. Output is the display text as a char
% row, preserving multi-line text entries.
function text = getReadonlyText(control)
    value = control.Value;
    text = char(join(string(value(:)), newline));
end
