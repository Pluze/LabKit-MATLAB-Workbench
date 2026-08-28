function roi = emptyRoi()
%EMPTYROI Return one ROI definition plus per-image center placement.
roi = struct("id", "", "name", "", ...
    "templateId", "template-1", "centerXY", [NaN NaN]);
end
