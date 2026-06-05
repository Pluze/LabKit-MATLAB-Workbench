% App-owned curvature axes limit helper. Expected caller: zoomAxesAtPoint.
% Inputs are requested limits and full limits. Output is clamped limits with
% width preserved when possible. This helper has no side effects.
function limits = clampLimits(limits, fullLimits)
%CLAMPLIMITS Clamp axes limits to full image limits.

    span = diff(limits);
    fullSpan = diff(fullLimits);
    if span >= fullSpan
        limits = fullLimits;
        return;
    end
    if limits(1) < fullLimits(1)
        limits = [fullLimits(1), fullLimits(1) + span];
    end
    if limits(2) > fullLimits(2)
        limits = [fullLimits(2) - span, fullLimits(2)];
    end
end
