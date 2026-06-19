% Expected caller: rhs_preview.run. Input is a semantic UI event. Output is
% the event id as a scalar string, or "" when absent.
function id = eventId(event)
%EVENTID Extract semantic control id from an event.

    id = "";
    if isstruct(event) && isfield(event, "id")
        id = string(event.id);
    elseif isobject(event) && isprop(event, "id")
        id = string(event.id);
    end
end
