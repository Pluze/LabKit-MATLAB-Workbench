% Expected caller: rhs_preview.run. Input is a MATLAB scroll-wheel event.
% Output is the vertical scroll count, or zero when unavailable.
function count = scrollWheelCount(event)
%SCROLLWHEELCOUNT Extract wheel delta from a scroll event.

    count = 0;
    if isstruct(event) && isfield(event, "VerticalScrollCount")
        count = double(event.VerticalScrollCount);
    elseif isobject(event) && isprop(event, "VerticalScrollCount")
        count = double(event.VerticalScrollCount);
    end
end
