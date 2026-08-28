function template = emptyTemplate()
%EMPTYTEMPLATE Return one reusable ROI geometry template.
template = struct("id", "", "name", "", ...
    "shape", "Rectangle", "size", [20 20]);
end
