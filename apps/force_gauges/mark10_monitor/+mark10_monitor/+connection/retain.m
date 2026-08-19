function box = retain(box, connection)
%RETAIN Keep the current connection in its managed resource box.
box("connection") = connection;
end
