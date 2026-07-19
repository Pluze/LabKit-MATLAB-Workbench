% App plot-choice owner; returns stable visible plot labels without side effects.
function value = choices()
%CHOICES Return user-facing T-Test Wizard plot choices.
%
% Expected callers: project defaults, layout, presenter, and plot renderer.
% The output owns stable visible plot type labels. Side effects are none.

    value = struct();
    value.types = ["Mean bars with SD", "Box plot"];
end
