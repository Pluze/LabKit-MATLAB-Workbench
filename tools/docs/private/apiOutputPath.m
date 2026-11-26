function path = apiOutputPath(symbol)
    path = "reference/api/" + replace(string(symbol), ".", "/") + ".html";
end
