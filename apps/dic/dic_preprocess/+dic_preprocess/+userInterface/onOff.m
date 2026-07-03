% Expected caller: DIC preprocess runner and direct unit tests. Input is a
% logical-like value. Output is the MATLAB UI Enable text value. Side effects:
% none.

function txt = onOff(tf)
%ONOFF Convert a logical value to a MATLAB UI on/off string.

    if tf
        txt = 'on';
    else
        txt = 'off';
    end
end
