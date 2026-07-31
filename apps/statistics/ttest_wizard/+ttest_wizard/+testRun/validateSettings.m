% App-owned implementation for ttest_wizard.testRun.validateSettings within the ttest_wizard product workflow.
function state = validateSettings(state, ~, context)
%VALIDATESETTINGS Keep the user-entered significance level in its legal range.
%
% Expected caller: test-setting OnValueChanged callbacks. The changed value
% is already applied by the binding; this callback validates the complete
% settings and repairs only an invalid alpha.

arguments
    state (1, 1) struct
    ~
    context (1, 1) labkit.app.CallbackContext
end

alpha = double(state.project.parameters.alpha);
if ~isscalar(alpha) || ~isfinite(alpha) || alpha <= 0 || alpha >= 1
    state.project.parameters.alpha = 0.05;
    context.alert( ...
        "Alpha must be between zero and one. It was reset to 0.05.", ...
        "Test settings");
end
end
