%STATUSNAMES Return frame-status enum names in storage order.
% Expected caller: annotation, CSV, UI, and tests.
function names = statusNames()
    names = ["empty"; "draft"; "confirmed"];
end
