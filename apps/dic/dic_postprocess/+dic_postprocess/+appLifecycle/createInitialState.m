% App-owned state factory for DIC Postprocess. Expected caller is the LabKit
% app runtime. Output is the mutable app state struct used by actions and
% render. Side effects are none.
function state = createInitialState()
    state = struct();
    state.matPath = "";
    state.referencePath = "";
    state.maskPath = "";
    state.strain = struct();
    state.referenceImage = [];
    state.maskImage = [];
    state.overlayExx = [];
    state.overlayEyy = [];
    state.summaryTable = table();
end
