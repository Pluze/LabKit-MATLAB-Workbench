% DIC family private helper. Expected caller: remaining DIC postprocess app code.
% Input is a string-like path. Output is display text. Side effects: none.
function txt = displayPath(pathValue)
    if strlength(pathValue) == 0
        txt = 'none';
    else
        txt = char(pathValue);
    end
end
