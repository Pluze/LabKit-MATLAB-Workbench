function safety = checkWaterWindowSafety(Emc, Ema, cathLimit, anodLimit)
%CHECKWATERWINDOWSAFETY Evaluate cathodic/anodic water-window safety.

    safety = struct();
    safety.cathOK = Emc >= cathLimit;
    safety.anodOK = Ema <= anodLimit;
    safety.safe = safety.cathOK && safety.anodOK;

    if safety.safe
        safety.limitSide = 'safe';
    elseif ~safety.cathOK && ~safety.anodOK
        safety.limitSide = 'both exceeded';
    elseif ~safety.cathOK
        safety.limitSide = 'cathodic exceeded';
    else
        safety.limitSide = 'anodic exceeded';
    end
end
