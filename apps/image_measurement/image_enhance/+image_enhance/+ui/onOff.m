% Expected caller: Image Enhance runner. Input is a logical or UI enable
% token. Output is MATLAB control Enable-compatible text.
function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end
