% Expected caller: DIC preprocess runner. Input is the active mask editor handle.
% Side effect: deletes the editor when present.

function clearMaskEditor(editor)
%CLEARMASKEDITOR Delete the DIC preprocess mask editor handle when present.

    if ~isempty(editor)
        editor.delete();
    end
end
