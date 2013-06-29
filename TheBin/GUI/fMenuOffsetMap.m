function fMenuOffsetMap(func,varargin)
switch func
    case 'AddTo'
        AddTo(varargin{1});
    case 'Clear'
        Clear(varargin{1});
    case 'Match'
        Match(varargin{1});
    case 'Load'
        Load(varargin{1});
    case 'Save'
        Save(varargin{1});    
    case 'Correct'
        Correct(varargin{1});          
    case 'Show'
        Show(varargin{1});         
end

function Show(hMainGui)
if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
    set(hMainGui.Menu.mShowOffsetMap,'Checked','Off');
    delete(findobj('Tag','pOffset'));
else
    set(hMainGui.Menu.mShowOffsetMap,'Checked','On');
    fShow('OffsetMap',hMainGui);  
end

function AddTo(hMainGui)
global Molecule;
global KymoTrackMol;
OffsetMap = getappdata(hMainGui.fig,'OffsetMap');
if OffsetMap.VisibleWarning==0
    OffsetMap.VisibleWarning=1;
end
Mode = get(gcbo,'UserData');
k = find([Molecule.Selected]==1);
XY = zeros(length(k),2);
for n = 1:length(k)
    XY(n,1)=mean(Molecule(k(n)).Results(:,3));
    XY(n,2)=mean(Molecule(k(n)).Results(:,4));    
    Molecule=fShared('SelectOne',Molecule,KymoTrackMol,k(n),0);
    Molecule=fShared('VisibleOne',Molecule,KymoTrackMol,hMainGui.RightPanel.pData.MolList,k(n),0,hMainGui.RightPanel.pData.sMolList);
end
k = ismember(XY,OffsetMap.RedXY);
XY(k(:,1)==1,:)=[];
k = ismember(XY,OffsetMap.GreenXY);
XY(k(:,1)==1,:)=[];   
if strcmp(Mode,'Red')
    OffsetMap.RedXY=[OffsetMap.RedXY; XY];
else
    OffsetMap.GreenXY=[OffsetMap.GreenXY; XY];
end
setappdata(hMainGui.fig,'OffsetMap',OffsetMap);
if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
    fShow('OffsetMap',hMainGui);  
end
fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
fShared('UpdateMenu',hMainGui);

function Clear(hMainGui)
OffsetMap = getappdata(hMainGui.fig,'OffsetMap');
Mode = get(gcbo,'UserData');
if strcmp(Mode,'Red')
    OffsetMap.RedXY=[];
elseif strcmp(Mode,'Green')
    OffsetMap.GreenXY=[];
else
    OffsetMap.RedXY=[];    
    OffsetMap.GreenXY=[];    
end
OffsetMap.Match=[];
setappdata(hMainGui.fig,'OffsetMap',OffsetMap);
if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
    fShow('OffsetMap',hMainGui);    
end
fShared('UpdateMenu',hMainGui);

function Match(hMainGui)
OffsetMap = getappdata(hMainGui.fig,'OffsetMap');
if size(OffsetMap.RedXY,1)~=size(OffsetMap.GreenXY,1)
    fMsgDlg('Number of offset points in the channels do not match','error');
    return;
else
    OffsetMap.Match=[];
    RedXY=OffsetMap.RedXY;
    GreenXY=OffsetMap.GreenXY;
    DiffX=mean(GreenXY(:,1))-mean(RedXY(:,1));
    GreenXY(:,1)=GreenXY(:,1)-DiffX;
    DiffY=mean(GreenXY(:,2))-mean(RedXY(:,2));
    GreenXY(:,2)=GreenXY(:,2)-DiffY;    
    Distance=zeros(size(RedXY,1));
    for i=1:size(RedXY,1)
        Distance(i,:)=sqrt((RedXY(i,1)-GreenXY(:,1)).^2 + (RedXY(i,2)-GreenXY(:,2)).^2);
    end
    while ~isempty(Distance);
        [m,x]=min(min(Distance,[],1));
        [m,y]=min(min(Distance,[],2));   
        OffsetMap.Match=[OffsetMap.Match; RedXY(y,:) GreenXY(x,:)+[DiffX DiffY] ];
        RedXY(y,:)=[]; 
        GreenXY(x,:)=[];
        Distance(y,:)=[];
        Distance(:,x)=[];
    end
end
setappdata(hMainGui.fig,'OffsetMap',OffsetMap);
if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
    fShow('OffsetMap',hMainGui);    
end
fShared('UpdateMenu',hMainGui);

function Load(hMainGui)
fRightPanel('CheckOffset',hMainGui);
[FileName, PathName] = uigetfile({'*.mat','FIESTA Offset Map(*.mat)'},'Load FIESTA Offset Map',fShared('GetLoadDir'));
if FileName~=0
    fShared('SetLoadDir',PathName);
    OffsetMap=fLoad([PathName FileName],'OffsetMap');
    setappdata(hMainGui.fig,'OffsetMap',OffsetMap);
    fShared('UpdateMenu',hMainGui);
end
setappdata(0,'hMainGui',hMainGui);

function Save(hMainGui)
OffsetMap=getappdata(hMainGui.fig,'OffsetMap'); %#ok<NASGU>
[FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Offset Map',fShared('GetSaveDir'));
if FileName~=0
    fShared('SetSaveDir',PathName);
    file = [PathName FileName];
    if isempty(findstr('.mat',file))
        file = [file '.mat'];
    end
    save(file,'OffsetMap');
end

function newData = CalcNewPos(data,Coeff)
newData(:,1)=data(:,1) * Coeff(1) + data(:,2) * Coeff(2) + Coeff(5);
newData(:,2)=data(:,1) * Coeff(3) + data(:,2) * Coeff(4) + Coeff(6);

function Correct(hMainGui)
global Molecule;
global Filament;
OffsetMap=getappdata(hMainGui.fig,'OffsetMap');
if ~isempty(OffsetMap.Match)
    m=size(OffsetMap.Match,1)*2;
    A=zeros(m,6);
    B=zeros(m,1);
    if strcmp(get(gcbo,'UserData'),'GreenRed')
        A(1:2:m,1:2)=OffsetMap.Match(:,3:4);
        A(2:2:m,3:4)=OffsetMap.Match(:,3:4);    
        B(1:2:m)=OffsetMap.Match(:,1);
        B(2:2:m)=OffsetMap.Match(:,2);
    else
        A(1:2:m,1:2)=OffsetMap.Match(:,1:2);
        A(2:2:m,3:4)=OffsetMap.Match(:,1:2);    
        B(1:2:m)=OffsetMap.Match(:,3);
        B(2:2:m)=OffsetMap.Match(:,4);
    end
    A(1:2:m,5)=1;
    A(2:2:m,6)=1;        
    Coeff=A\B;
    k = find([Molecule.Selected]==1);
    for n = k
        Molecule(n).Results(:,3:4) = CalcNewPos(Molecule(n).Results(:,3:4),Coeff);
    end
    k = find([Filament.Selected]==1);
    for n = k
        Filament(n).Results(:,3:4) = CalcNewPos(Filament(n).Results(:,3:4),Coeff);
        Filament(n).PosStart = CalcNewPos(Filament(n).PosStart,Coeff);
        Filament(n).PosCenter = CalcNewPos(Filament(n).PosCenter,Coeff);
        Filament(n).PosEnd = CalcNewPos(Filament(n).PosEnd,Coeff);
        for m = 1:length(Filament(n).Data)
            Filament(n).Data{m}(:,1:2) =  CalcNewPos(Filament(n).Data{m}(:,1:2),Coeff);
        end
    end
    fShow('Marker',hMainGui,hMainGui.Values.FrameIdx);
    fShow('Tracks');
end