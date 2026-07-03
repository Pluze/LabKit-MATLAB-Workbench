% Initial state factory for Focus Stack. Expected caller is
% focus_stack.definition. Output is the app-owned model consumed by actions
% and UI update functions.
function state = createInitialState()
    state = struct();
    state.folder = "";
    state.sourceLocation = "No images loaded";
    state.paths = strings(0, 1);
    state.images = {};
    state.alignedImages = {};
    state.registrationLines = {};
    state.result = focus_stack.appState.emptyResult();
    state.lastRunFingerprint = "";
end
