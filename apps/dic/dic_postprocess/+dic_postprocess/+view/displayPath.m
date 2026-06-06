% DIC Postprocess view helper. Expected caller: labkit_DICPostprocess_app.
% Input is a string-like path. Output is display text. Side effects: none.
function txt = displayPath(pathValue)
    if strlength(pathValue) == 0
        txt = 'none';
    else
        txt = char(pathValue);
    end
end
