% Expected caller: labkit.rhs public functions. Input is a char/string file
% path. Output is a char row path; invalid input raises a public RHS error.
function filepath = normalizeFilepath(filepath)
    if ~(ischar(filepath) || (isstring(filepath) && isscalar(filepath)))
        error("labkit:rhs:InvalidFilepath", ...
            "Filepath must be a character vector or scalar string.");
    end
    filepath = char(filepath);
end
