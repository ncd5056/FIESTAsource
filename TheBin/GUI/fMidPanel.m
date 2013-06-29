function fMidPanel(func,varargin)
switch func
    case 'sFrame'
        sFrame(varargin{1});
    case 'eFrame'
        eFrame(varargin{1});
    case 'Update'
        Update(varargin{1});
end

function Update(hMainGui)
global StackInfo
set(hMainGui.MidPanel.tInfoTime,'String',sprintf('Time: %0.3f s',(StackInfo.CreationTime(hMainGui.Values.FrameIdx)-StackInfo.CreationTime(1))/1000));
setappdata(0,'hMainGui',hMainGui);
fShared('ReturnFocus');
fShow('Image');

function sFrame(hMainGui)
idx=round(get(hMainGui.MidPanel.sFrame,'Value'));
if idx<1
    hMainGui.Values.FrameIdx=1;
elseif idx>hMainGui.Values.MaxIdx
    hMainGui.Values.FrameIdx=hMainGui.Values.MaxIdx;
else
    hMainGui.Values.FrameIdx=idx;
end
setappdata(0,'hMainGui',hMainGui);
set(hMainGui.MidPanel.eFrame,'String',int2str(hMainGui.Values.FrameIdx));
Update(hMainGui);


function eFrame(hMainGui)
try
    idx=round(str2double(get(hMainGui.MidPanel.eFrame,'String')));
catch
end
if idx<1
    hMainGui.Values.FrameIdx=1;
elseif idx>hMainGui.Values.MaxIdx
    hMainGui.Values.FrameIdx=hMainGui.Values.MaxIdx;
elseif ~isnan(idx)
    hMainGui.Values.FrameIdx=idx;
end
setappdata(0,'hMainGui',hMainGui);
set(hMainGui.MidPanel.eFrame,'String',int2str(hMainGui.Values.FrameIdx));
set(hMainGui.MidPanel.sFrame,'Value',hMainGui.Values.FrameIdx);
Update(hMainGui);