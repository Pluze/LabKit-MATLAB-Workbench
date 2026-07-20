% Expected caller: FLIR thermal runner. Input is an ROI mode string. Output
% is the user-facing label for that mode. Side effects: none.
function label = roiModeLabel(mode)

    labels = flir_thermal.thermalPreview.presentationData.rangeControlLabels();
    switch string(mode)
        case "hot"
            label = labels.roiHotSpot;
        case "cold"
            label = labels.roiColdSpot;
        otherwise
            label = labels.roiMean;
    end
end
