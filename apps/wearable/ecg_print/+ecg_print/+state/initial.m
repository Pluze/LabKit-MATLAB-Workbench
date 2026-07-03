% Initial state for ECG Print. Expected caller is ecg_print.definition.
% Output is the app-owned model consumed by actions and renderers.
function state = initial()
    state = struct();
    state.recording = [];
    state.signal = [];
    state.workingSignal = [];
    state.filteredSignal = [];
    state.events = [];
    state.segments = [];
    state.template = [];
    state.measurements = [];
    state.filepath = "";
    state.fileStatus = "No file loaded";
    state.importStatus = "Open a recording to inspect import settings.";
    state.filePreview = {'Open a CSV/text file, then use Preview file header.'};
    state.channelItems = {'(none)'};
    state.selectedChannel = "(none)";
end
