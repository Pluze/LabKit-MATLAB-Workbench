function files = discoverLabKitAppApiFiles(root)
%DISCOVERLABKITAPPAPIFILES Find App functions with complete public help.
%
% Expected caller: documentation and public-help contract tests. Input is the
% repository root. Output is a sorted string vector of App-owned .m files
% whose help declares the complete public contract used by the HTML renderer.

    entries = dir(fullfile(root, "apps", "**", "*.m"));
    files = strings(0, 1);
    required = [ ...
        "^%\s+(?:Usage|Syntax):\s*$"
        "^%\s+Inputs:\s*$"
        "^%\s+Outputs:\s*$"
        "^%\s+(?:Errors|Failure Behavior):\s*$"
        "^%\s+See also\s+\S+"];
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        text = fileread(filepath);
        isPublic = true;
        for iPattern = 1:numel(required)
            if isempty(regexp(text, required(iPattern), ...
                    "once", "lineanchors"))
                isPublic = false;
                break;
            end
        end
        if isPublic
            files(end + 1, 1) = filepath;
        end
    end
    files = sort(files);
end
