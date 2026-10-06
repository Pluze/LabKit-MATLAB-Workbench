classdef (Hidden, Sealed) PlotWindows < handle
    % Own auxiliary plot lifetimes for MatlabPlatformAdapter; no App handles.
    % update consumes a compiled plot node and its validated snapshot value.
    properties (Access=private)
        Entries
    end
    methods
        function obj=PlotWindows()
            obj.Entries=containers.Map("KeyType","char","ValueType","any");
        end
        function update(obj,node,value,title,visibility)
            key=char(node.Id);
            if ~isKey(obj.Entries,key)
                obj.Entries(key)=struct("figure",[],"axes",[],"request",0,"revision",[]);
            end
            entry=obj.Entries(key);
            alive=~isempty(entry.figure)&&isgraphics(entry.figure);
            if value.WindowRequest==0
                if alive, delete(entry.figure); end
                entry.figure=[]; entry.request=0; obj.Entries(key)=entry; return;
            end
            newRequest=value.WindowRequest~=entry.request;
            if ~alive && ~newRequest, return; end
            if ~alive
                entry.figure=uifigure(Name=title,Visible="off",Tag="labkitPlotWindow."+node.Id, ...
                    Position=[100 100 1100 760]);
                count=numel(node.AxisIds); cols=min(2,count); rows=ceil(count/cols);
                grid=uigridlayout(entry.figure,[rows cols]);
                entry.axes=gobjects(1,count);
                for k=1:count
                    entry.axes(k)=uiaxes(grid,Tag=node.Id+"."+node.AxisIds(k));
                end
            end
            entry.request=value.WindowRequest;
            obj.Entries(key)=entry;
            viewport=labkit.app.internal.native.NativeAdapterValues.captureViewport(entry.axes);
            preserve=alive && isequal(entry.revision,value.ViewRevision);
            axesById=struct();
            for k=1:numel(node.AxisIds), axesById.(node.AxisIds(k))=entry.axes(k); end
            node.Renderer(axesById,value.Model);
            if preserve
                labkit.app.internal.native.NativeAdapterValues.restoreViewport(entry.axes,viewport);
            end
            entry.figure.Name=title;
            entry.revision=value.ViewRevision;
            if newRequest
                entry.figure.Visible=visibility;
                if string(visibility)=="on", figure(entry.figure); end
            end
            obj.Entries(key)=entry;
        end
        function close(obj)
            keys=obj.Entries.keys;
            for k=1:numel(keys)
                entry=obj.Entries(keys{k});
                if ~isempty(entry.figure)&&isgraphics(entry.figure), delete(entry.figure); end
            end
            obj.Entries=containers.Map("KeyType","char","ValueType","any");
        end
        function delete(obj)
            obj.close();
        end
    end
end
