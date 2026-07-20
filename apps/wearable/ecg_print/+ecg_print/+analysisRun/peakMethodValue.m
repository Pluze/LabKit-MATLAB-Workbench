% Expected caller: ecg_print direct callbacks and direct unit tests. Input is the UI
% dropdown label. Output is the method string accepted by
% labkit.biosignal.detectEcgPeaks. Side effects: none.

function method = peakMethodValue(label)
%PEAKMETHODVALUE Map ECG Print UI labels to biosignal peak detector methods.

    switch string(label)
        case "Pan-Tompkins"
            method = "pan-tompkins";
        case "Local peaks"
            method = "local";
        otherwise
            method = "qrs-streaming";
    end
end
