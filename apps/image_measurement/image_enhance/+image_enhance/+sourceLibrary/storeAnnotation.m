function items = storeAnnotation(items, annotation)
%STOREANNOTATION Materialize or replace one source-ID keyed annotation.
index=find(string({items.sourceId})==string(annotation.sourceId),1);
if isempty(index),items(end+1,1)=annotation;else,items(index)=annotation;end
end
