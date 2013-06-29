function fMenuView(func,varargin)
switch func
    case 'View'
        View(varargin{1},varargin{2});
    case 'ViewCheck'
        ViewCheck;
    case 'RedGreenOverlay'
        RedGreenOverlay;
end

function View(hMainGui,idx)
if ~isempty(idx)
   hMainGui.Values.FrameIdx=idx;
else
   hMainGui.Values.FrameIdx=round(get(hMainGui.MidPanel.sFrame,'Value')); 
end
setappdata(0,'hMainGui',hMainGui);
fShow('Image');

function ViewCheck
if strcmp(get(gcbo,'Checked'),'on')==1
    set(gcbo,'Checked','off');
else
    set(gcbo,'Checked','on');
end
fShow('Image');

function RedGreenOverlay
if strcmp(get(gcbo,'Checked'),'on')==1
    set(gcbo,'Checked','off');
else
    set(gcbo,'Checked','on');
end
fShow('Image');
fShow('Tracks');
