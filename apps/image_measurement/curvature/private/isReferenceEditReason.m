% App-owned curvature scale-tool reason helper. Expected caller:
% labkit_CurvatureMeasurement_app calibration callbacks. Input is a reason value.
% Output is true for reference-edit lifecycle reasons.
function tf = isReferenceEditReason(reason)
%ISREFERENCEEDITREASON Return true for reference edit lifecycle reasons.

    tf = false;
    if ischar(reason)
        text = string(reason);
    elseif isstring(reason) && isscalar(reason)
        text = reason;
    else
        return;
    end
    tf = any(text == ["set points", "add point", "delete point", ...
        "move point", "clear points", "start", "finish"]);
end
