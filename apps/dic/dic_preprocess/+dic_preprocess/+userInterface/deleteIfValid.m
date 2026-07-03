% Expected caller: DIC preprocess runner. Input is a graphics or listener handle.
% Side effect: deletes the handle when present and valid.

function deleteIfValid(h)
%DELETEIFVALID Delete a MATLAB handle when it is nonempty and valid.

    if isempty(h)
        return;
    end
    if isvalid(h)
        delete(h);
    end
end
