function mode = labkitDefaultGuiMode()
%LABKITDEFAULTGUIMODE Return the default official GUI test visibility mode.

    mode = string(getenv("LABKIT_GUI_TEST_MODE"));
    if strlength(strtrim(mode)) == 0
        mode = "hidden";
    end
end
