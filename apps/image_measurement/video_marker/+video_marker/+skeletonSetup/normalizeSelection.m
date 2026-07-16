% Expected callers: skeleton actions and marker import. Input is canonical
% Video Marker state. Output keeps selected rows and connection endpoints
% valid for the current ordered skeleton; resetRows clears table selections.
function state = normalizeSelection(state, resetRows)
    if nargin < 2
        resetRows = false;
    end
    if resetRows
        state.session.selection.selectedPointIndex = 0;
        state.session.selection.selectedEdgeIndex = 0;
    end
    names = string(state.project.annotations.skeleton.pointNames(:));
    if isempty(names)
        state.session.selection.connectionFrom = "";
        state.session.selection.connectionTo = "";
        return;
    end
    from = string(state.session.selection.connectionFrom);
    if ~any(names == from)
        from = names(1);
    end
    candidates = names(names ~= from);
    to = string(state.session.selection.connectionTo);
    if isempty(candidates)
        to = "";
    elseif ~any(candidates == to)
        to = candidates(1);
    end
    state.session.selection.connectionFrom = from;
    state.session.selection.connectionTo = to;
end
