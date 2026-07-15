function writeDocText(filepath, content)
%WRITEDOCTEXT Write deterministic UTF-8 text and create parent folders.

    folder = fileparts(char(filepath));
    if ~isfolder(folder)
        mkdir(folder);
    end
    fid = fopen(filepath, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Docs:WriteFailed", ...
            "Could not write generated documentation file %s.", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(string(content)));
    clear cleanup
end
