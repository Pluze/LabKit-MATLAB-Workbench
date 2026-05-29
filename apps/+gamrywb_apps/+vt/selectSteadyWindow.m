function [t1, t2] = selectSteadyWindow(p1, p2, modeText)
%SELECTSTEADYWINDOW Return steady-state window bounds for a pulse.

    t1 = p1;
    t2 = p2;
    if strcmp(modeText, 'Center 60% median') && isfinite(p1) && isfinite(p2) && p2 > p1
        dt = p2 - p1;
        t1 = p1 + 0.20 * dt;
        t2 = p1 + 0.80 * dt;
    end
end
