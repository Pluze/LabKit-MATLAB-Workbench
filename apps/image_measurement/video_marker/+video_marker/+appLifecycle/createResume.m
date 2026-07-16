% Expected caller: V2 project/recovery encoding. Inputs are current session
% and project. Output is optional, non-authoritative navigation convenience.
function resume = createResume(session, ~)
    resume = struct("currentFrame", ...
        double(session.selection.currentFrame));
end
