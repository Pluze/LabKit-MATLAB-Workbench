function applicationState = changeGamma( ...
        applicationState, gammaValue, ~)
%CHANGEGAMMA Normalize display gamma without changing thermal values.
gammaValue = ...
    flir_thermal.thermalPreview.presentationData.normalizeGammaValue( ...
        gammaValue);
applicationState.project.parameters.gammaValue = gammaValue;

applicationState.project.results.resultManifestPath = "";
end
