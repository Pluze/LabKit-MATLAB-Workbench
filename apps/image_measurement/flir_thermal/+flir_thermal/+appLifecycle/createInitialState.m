% App-owned state factory for FLIR Thermal. Expected caller is the LabKit
% app runtime. Output is the mutable app state struct used by actions.
% Side effects are limited to resolving the default output folder.
function S = createInitialState()
    S = struct();
    S.items = repmat(flir_thermal.appState.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.outputFolder = string(labkit.ui.runtime.defaultDialogFolder("output"));
    S.lastExport = [];
    S.roiMode = "mean";
end
