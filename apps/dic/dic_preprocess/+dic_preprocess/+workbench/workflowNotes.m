function lines = workflowNotes()
%WORKFLOWNOTES Return the static DIC preprocessing workflow instructions.
% Expected caller: workbench.present. Output is a string column and has no
% side effects.

lines = [
    "1. Load a reference image and a moving image."
    "2. Start point matching, alternate between reference and moving features, then apply alignment."
    "3. False-color preview compares the current pair even before alignment."
    "4. Align or crop the current working pair in any order; each applied operation can be undone."
    "5. Draw curve or straight-line ROI boundaries, add/subtract them on the mask canvas, then save the mask."];
end
