function fMenuContext(func,varargin)
switch func
    case 'DeleteRegion'
        DeleteRegion(varargin{1});        
    case 'DeleteMeasure'
        DeleteMeasure(varargin{1});  
    case 'TransferTrackInfo'
        TransferTrackInfo(varargin{1});  
    case 'OpenTrack'
        OpenTrack(varargin{1});  
    case 'MarkTrack'
        MarkTrack(varargin{1});        
    case 'SelectTrack'
        SelectTrack(varargin{1});     
    case 'SelectList'
        SelectList(varargin{1});             
    case 'VisibleList'
        VisibleList(varargin{1});                     
    case 'SetCurrentTrack'
        SetCurrentTrack(varargin{1},varargin{2});                     
    case 'AddTo'
        AddTo(varargin{1});
    case 'DeleteObject'
        DeleteObject(varargin{1});        
    case 'DeleteQueue'
        DeleteQueue;           
    case 'DeleteOffset'
        DeleteOffset(varargin{1});           
    case 'DeleteOffsetMatch'
        DeleteOffsetMatch(varargin{1});    
    case 'EstimateFWHM'
        EstimateFWHM(varargin{1});    
end     

function SelectList(hMainGui)
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
Mode=get(gcbo,'UserData');
for n=1:length(Molecule)
    if Molecule(n).Selected==0||Molecule(n).Selected==1
        v=[];
        if strcmp(Mode,'All')||strcmp(Mode,'Molecule')
            v=1;
        elseif strcmp(Mode,'Filament')
            v=0;
        end
        Molecule=fShared('SelectOne',Molecule,KymoTrackMol,n,v);
    end
end
for n=1:length(Filament)
    if Filament(n).Selected==0||Filament(n).Selected==1
        v=[];
        if strcmp(Mode,'All')||strcmp(Mode,'Filament')
            v=1;
        elseif strcmp(Mode,'Molecule')
            v=0;
        end
        Filament=fShared('SelectOne',Filament,KymoTrackFil,n,v);
    end
end
fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
fShow('Image');

function VisibleList(hMainGui)
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
Mode=get(gcbo,'UserData');
for n=1:length(Molecule)
    if Molecule(n).Selected>-1
        if strcmp(Mode,'All')
            Molecule=fShared('VisibleOne',Molecule,KymoTrackMol,hMainGui.RightPanel.pData.MolList,n,1,hMainGui.RightPanel.pData.sMolList);
        else
            if Molecule(n).Selected==1
                Molecule=fShared('VisibleOne',Molecule,KymoTrackMol,hMainGui.RightPanel.pData.MolList,n,[],hMainGui.RightPanel.pData.sMolList);            
            end
        end
    end
end
for n=1:length(Filament)
    if Filament(n).Selected>-1
        if strcmp(Mode,'All')
            Filament=fShared('VisibleOne',Filament,KymoTrackFil,hMainGui.RightPanel.pData.FilList,n,1,hMainGui.RightPanel.pData.sFilList);
        else
            if Filament(n).Selected==1
                Filament=fShared('VisibleOne',Filament,KymoTrackFil,hMainGui.RightPanel.pData.FilList,n,[],hMainGui.RightPanel.pData.sFilList);
            end
        end
    end
end
fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
fShow('Image');

function DeleteQueue
global Queue;
Mode=get(gcbo,'UserData');
if ~isempty(Queue)
    if strcmp(Mode,'All')==1
        Queue=[];
    else
        Selected=[Queue.Selected];
        Queue(Selected==1)=[];
    end
    fRightPanel('UpdateQueue','Local');
end

function [Object,OtherObject]=CurrentTrack(Object,OtherObject,n)
Selected=[Object.Selected];
k=find(Selected==2,1);
if ~isempty(k)
    Object(k).Selected=0;
    if k~=n
        Object(n).Selected=2; 
        set(Object(n).PlotHandles(2:3),'Visible','off');
    end
else
    Object(n).Selected=2;
    set(Object(n).PlotHandles(2:3),'Visible','off');    
end
Selected=[OtherObject.Selected];
k=find(Selected==2,1);
if ~isempty(k)
    OtherObject(k).Selected=0;
end

function SetCurrentTrack(hMainGui,Mode)
global Molecule;
global Filament;
TrackInfo=get(hMainGui.Menu.ctTrack(1).menu,'UserData');
n=[];
if strcmp(Mode,'Set')
    if isempty(TrackInfo)
        TrackInfo=get(gco,'UserData');
        set(gco,'UserData',[]);
    end
    if ~isempty(TrackInfo)
        n=TrackInfo.List(1);
        Mode=TrackInfo.Mode;
    end
else
    n=find([Molecule.Selected]==2,1);
    Mode='Molecule';
    if isempty(n)
        n=find([Filament.Selected]==2,1);        
        Mode='Filament';
    end
end
if ~isempty(n)
    if strcmp(Mode,'Molecule')
        [Molecule,Filament]=CurrentTrack(Molecule,Filament,n);
    else
        [Filament,Molecule]=CurrentTrack(Filament,Molecule,n);
    end
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
end


function TransferTrackInfo(hMainGui)
global TrackInfo;
set(hMainGui.Menu.ctTrack(1).menu,'UserData',TrackInfo);

function OpenTrack(hMainGui)
TrackInfo=get(hMainGui.Menu.ctTrack(1).menu,'UserData');
if ~isempty(TrackInfo)
    n=TrackInfo.List(1);
    fMainGui('OpenObject',hMainGui,TrackInfo.Mode,n)
end

function Object=SetColor(Object,KymoObject,color,n)
Object(n).Color=color;
set(Object(n).PlotHandles(1),'Color',color);
k=find([KymoObject.Index]==n);
if ~isempty(k)
    set(KymoObject(k).PlotHandles(1),'Color',color);            
end

function MarkTrack(hMainGui)
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
TrackInfo=get(hMainGui.Menu.ctTrack(1).menu,'UserData');
if ~isempty(TrackInfo)
    n=TrackInfo.List(1);
    color=get(gcbo,'UserData');
    if strcmp(TrackInfo.Mode,'Molecule')
        Molecule=SetColor(Molecule,KymoTrackMol,color,n);
    else
        Filament=SetColor(Filament,KymoTrackFil,color,n);
    end
end
fShow('Image');

function SelectTrack(hMainGui)
TrackInfo=get(hMainGui.Menu.ctTrack(1).menu,'UserData');
if ~isempty(TrackInfo)
    n=TrackInfo.List(1);
    fMainGui('SelectObject',hMainGui,TrackInfo.Mode,n,get(gcbo,'UserData'));
end

function DeleteRegion(hMainGui)
if strcmp(get(gcbo,'UserData'),'one')==1
    sRegion=get(gco,'UserData');
    nRegion=sRegion;
else
    sRegion=1;
    nRegion=length(hMainGui.Region);
end
for i=nRegion:-1:sRegion
    hMainGui.Region(i)=[];
    try
        delete(hMainGui.Plots.Region(i));
        hMainGui.Plots.Region(i)=[];
    catch
    end
end
for i=sRegion:length(hMainGui.Region)
    hMainGui.Region(i).color=hMainGui.RegionColor(mod(i-1,24)+1,:);
    set(hMainGui.Plots.Region(i),'Color',hMainGui.Region(i).color,'Linestyle','--','UserData',i,'UIContextMenu',hMainGui.Menu.ctRegion);
end
setappdata(0,'hMainGui',hMainGui);
fLeftPanel('RegUpdateList',hMainGui);

function EstimateFWHM(hMainGui)
global Config;
hPlot = findobj('Tag','plotLineScan');
D=get(hPlot,'XData')';
I=get(hPlot,'YData')';
lb = [0 0 0 0];
ub = [max(I) 3*(max(I)-mean(I)) Inf max(D)];
params0 = [mean(I) max(I)-mean(I) 0.5 D(I==max(I))];
s = fitoptions('Method','NonlinearLeastSquares','Lower',lb,'Upper',ub,'Startpoint',params0);
f = fittype('b+h*exp(-0.5*(x-x0)^2/s^2)','options',s);
g = fit(D,I,f);
FWHM = round(g.s*2*sqrt(2*log(2))*1000);
button =  fQuestDlg({'Results of the FWHM Estimation:','Function I=b+exp(-0.5*(x-x0)^2/s^2)',['b=' num2str(round(g.b)) ', h=' num2str(round(g.h)) ', x0=' num2str(round(g.x0*100)/100) ', s=' num2str(round(g.s*100)/100)],['Results in a FWHM of ' num2str(FWHM) 'nm']},'FWHM Estimate',{'Apply to configuration','Cancel'},'Apply to configuration');       
if strcmp(button,'Apply to configuration')
    Config.Threshold.FWHM = FWHM;
end

function DeleteMeasure(hMainGui)
fToolBar('Cursor',hMainGui);
hMainGui=getappdata(0,'hMainGui');
if strcmp(get(gcbo,'UserData'),'one')==1
    sMeasure=get(gco,'UserData');
    if sMeasure>0
        nMeasure=sMeasure;
        set(hMainGui.RightPanel.pTools.lMeasureTable,'Value',sMeasure,'UserData',sMeasure-1)
    else
        nMeasure=length(hMainGui.Measure);
        sMeasure=length(hMainGui.Measure)+1;
    end
else
    sMeasure=1;
    nMeasure=length(hMainGui.Measure);
end
for i=nMeasure:-1:sMeasure
    hMainGui.Measure(i)=[];
    delete(hMainGui.Plots.Measure(i));
    hMainGui.Plots.Measure(i)=[];
end
for i=sMeasure:length(hMainGui.Measure)
    delete(hMainGui.Plots.Measure(i));
    hold on
    color=mod(i-1,8)+1;
    hMainGui.Plots.Measure(i)=plot(hMainGui.Measure(i).X,hMainGui.Measure(i).Y,'Color',get(hMainGui.LeftPanel.pRegions.cRegion(color),...
                                 'ForegroundColor'),'LineStyle',':','UserData',i,'UIContextMenu',hMainGui.Menu.ctMeasure);
    hold off
end
setappdata(0,'hMainGui',hMainGui);
fRightPanel('UpdateMeasure',hMainGui);

function DeleteObject(hMainGui)
global Objects;
Mode=get(gcbo,'UserData');
n=get(gco,'UserData');
if strcmp(Mode,'Molecule')
    k=find(double([Objects{hMainGui.Values.FrameIdx}.length])==0);
else
    k=find(double([Objects{hMainGui.Values.FrameIdx}.length])~=0);    
end
Objects{hMainGui.Values.FrameIdx}.center_x(k(n))=[];
Objects{hMainGui.Values.FrameIdx}.center_y(k(n))=[];
Objects{hMainGui.Values.FrameIdx}.com_x(:,k(n))=[];
Objects{hMainGui.Values.FrameIdx}.com_y(:,k(n))=[];
Objects{hMainGui.Values.FrameIdx}.orientation(:,k(n))=[];
Objects{hMainGui.Values.FrameIdx}.length(:,k(n))=[];
Objects{hMainGui.Values.FrameIdx}.width(:,k(n))=[];
Objects{hMainGui.Values.FrameIdx}.height(:,k(n))=[];
Objects{hMainGui.Values.FrameIdx}.background(:,k(n))=[];
Objects{hMainGui.Values.FrameIdx}.data(k(n))=[];
fShow('Marker',hMainGui,hMainGui.Values.FrameIdx);  

function DeleteOffset(hMainGui)
OffsetMap = getappdata(hMainGui.fig,'OffsetMap');
n=get(gco,'UserData');
if isreal(n)
    if ~isempty(OffsetMap.Match)
        k = ismember(OffsetMap.Match(:,1:2),OffsetMap.RedXY(n,:));
        if max(k(:,1))==1
            OffsetMap.Match(k(:,1),:)=[];
        end
    end
    OffsetMap.RedXY(n,:)=[];
else
    n=imag(n);
    if ~isempty(OffsetMap.Match)
        k = ismember(OffsetMap.Match(:,3:4),OffsetMap.GreenXY(n,:));
        if max(k(:,1))==1
            OffsetMap.Match(k(:,1),:)=[];
        end
    end
    OffsetMap.GreenXY(n,:)=[];  
end
setappdata(hMainGui.fig,'OffsetMap',OffsetMap);
if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
    fShow('OffsetMap',hMainGui);    
end
fShared('UpdateMenu',hMainGui);

function DeleteOffsetMatch(hMainGui)
OffsetMap = getappdata(hMainGui.fig,'OffsetMap');
n=get(gco,'UserData');
if ~isempty(OffsetMap.RedXY) && ~isempty(OffsetMap.GreenXY) && ~isempty(OffsetMap.Match)
    k = ismember(OffsetMap.RedXY,OffsetMap.Match(n,1:2));
    if max(k(:,1))==1
        OffsetMap.RedXY(k(:,1),:)=[];
    end
    k = ismember(OffsetMap.GreenXY,OffsetMap.Match(n,3:4));
    if max(k(:,1))==1
        OffsetMap.GreenXY(k(:,1),:)=[];
    end
    OffsetMap.Match(n,:)=[];
end
setappdata(hMainGui.fig,'OffsetMap',OffsetMap);
if strcmp(get(hMainGui.Menu.mShowOffsetMap,'Checked'),'on')
    fShow('OffsetMap',hMainGui);    
end
fShared('UpdateMenu',hMainGui);

function AddTo(hMainGui)
global Config;
global Objects;
global Molecule;
global Filament;
Mode=get(gcbo,'UserData');
n=get(gco,'UserData');
if strcmp(Mode{1},'Molecule')
    Object=Molecule;
else
    Object=Filament;
end
nObj=length(Object);
kObj=[];
kData=[];
if strcmp(Mode{2},'New')==1
    Object(nObj+1).Selected=0;
    Object(nObj+1).Visible=1;
    Object(nObj+1).Name=sprintf('%s %d',Mode{1},nObj+1); 
    Object(nObj+1).Directory=Config.Directory;
    Object(nObj+1).File=Config.StackName;
    Object(nObj+1).Color=[0 0 1];
    Object(nObj+1).Drift=0;
    Object(nObj+1).PixelSize=Config.PixSize;
    kObj=nObj+1;
    kData=1;
else
    if nObj==0
        fMsgDlg(['No ' Mode{1} ' present'],'error');
        return;
    else
        idx=find([Object.Selected]==2,1);
        if isempty(idx)
            fMsgDlg(['No Current' Mode{1} ' Track'],'error');
            return;
        else
            if ~isempty(find(Object(idx).Results(:,1)==hMainGui.Values.FrameIdx, 1))
                button = fQuestDlg('Overwrite current frame?','FIESTA Warning',{'OK','Cancel'},'OK');
                if strcmp(button,'OK') && ~isempty(button)
                    kData=find(Object(idx).Results(:,1)==hMainGui.Values.FrameIdx,1);
                else 
                    return;
                end
            end
            kObj=idx;
        end
    end
end
if ~isempty(kObj)
    if strcmp(Mode{1},'Molecule')
        Molecule=AddDataMol(Object,Objects,kObj,kData,hMainGui.Values.FrameIdx,n);
        Molecule(kObj).Results(:,5) = fDis(Molecule(kObj).Results(:,3:4));
    else
        Filament=AddDataFil(Object,Objects,kObj,kData,hMainGui.Values.FrameIdx,n);
        if strcmp(Config.RefPoint,'center')==1
            Filament(kObj).Results(:,3:4) = Filament(kObj).PosCenter;
        elseif strcmp(Config.RefPoint,'start')==1
            Filament(kObj).Results(:,3:4) = Filament(kObj).PosStart;
        else
            Filament(kObj).Results(:,3:4) = Filament(kObj).PosEnd;
        end
        Filament(kObj).Results(:,5) = fDis(Filament(kObj).Results(:,3:4));
    end
end
fShow('Image');  
fShow('Tracks');
if strcmp(Mode{1},'Molecule')&&strcmp(Mode{2},'New')
    [Molecule,Filament]=CurrentTrack(Molecule,Filament,kObj);
elseif strcmp(Mode{1},'Filament')&&strcmp(Mode{2},'New')
    [Filament,Molecule]=CurrentTrack(Filament,Molecule,kObj);
end
fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
fShared('UpdateMenu',hMainGui);

function Molecule=AddDataMol(Molecule,Objects,nMol,nData,idx,k)
if ~isempty(Molecule(nMol).Results) && isempty(nData)
    f=find(idx<Molecule(nMol).Results(:,1),1,'first');
    if ~isempty(f)
        n=size(Molecule(nMol).Results,1);
        nData=f;
        Molecule(nMol).Results(f+1:n+1,:)=Molecule(nMol).Results(f:n,:);
    else
        nData=size(Molecule(nMol).Results,1)+1;
    end
end

Molecule(nMol).Results(nData,1) = single(idx);
Molecule(nMol).Results(nData,2) = Objects{idx}.time;
Molecule(nMol).Results(nData,3) = Objects{idx}.center_x(k);
Molecule(nMol).Results(nData,4) = Objects{idx}.center_y(k);
Molecule(nMol).Results(nData,6) = Objects{idx}.width(1,k);
Molecule(nMol).Results(nData,7) = Objects{idx}.height(1,k);                
Molecule(nMol).Results(nData,8) = single(sqrt((Objects{idx}.com_x(2,k))^2+(Objects{idx}.com_y(2,k))^2));
Molecule(nMol).Results(:,5) = fDis(Molecule(nMol).Results(:,3:4));

if size(Objects{idx}.data{k},2)==1
    Molecule(nMol).Results(nData,9:10) = Objects{idx}.data{k}';                
    Molecule(nMol).Results(nData,11) = single(mod(Objects{idx}.orientation(1,k),2*pi));                
    Molecule(nMol).Type = 'stretched';
elseif size(Objects{idx}.data{k},2)==3
    Molecule(nMol).Results(nData,9:11) = Objects{idx}.data{k}(1,:);                
    Molecule(nMol).Type = 'ring1';
    if size(Objects{idx}.data{k},1)>1
        Molecule(nMol).Results(nData,12:14) = Objects{idx}.data{k}(2,:);
        Molecule(nMol).Type = 'ring2';
    end
else
    Molecule(nMol).Type = 'symmetric';
end

function Filament=AddDataFil(Filament,Objects,nFil,nData,idx,k)
if ~isempty(Filament(nFil).Results) && isempty(nData)
    f=find(idx<Filament(nFil).Results(:,1),1);
    if ~isempty(f)
        n=size(Filament(nFil).Results,1);
        nData=f;
        Filament(nFil).Results(f+1:n+1,:) = Filament(nFil).Results(f:n,:);
        Filament(nFil).PosStart(f+1:n+1,:) = Filament(nFil).PosStart(f:n,:);
        Filament(nFil).PosCenter(f+1:n+1,:) = Filament(nFil).PosCenter(f:n,:);
        Filament(nFil).PosEnd(f+1:n+1,:) = Filament(nFil).PosEnd(f:n,:);
        Filament(nFil).Data(f+1:n+1) = Filament(nFil).Data(f:n);        
    else
        nData = size(Filament(nFil).Results,1) + 1;
    end
end

Filament(nFil).Results(nData,1) = single(idx);
Filament(nFil).Results(nData,2) = Objects{idx}.time;
Filament(nFil).Results(nData,3) = Objects{idx}.center_x(k);
Filament(nFil).Results(nData,4) = Objects{idx}.center_y(k);
Filament(nFil).Results(nData,6) = Objects{idx}.length(1,k);
Filament(nFil).Results(nData,7) = Objects{idx}.height(1,k);                
Filament(nFil).Results(nData,8) = single( mod(Objects{idx}.orientation(1,k),2*pi) );

Filament(nFil).Data{nData} = Objects{idx}.data{k};

if nData > 1
    if abs(Filament(nFil).Results(nData,8)-Filament(nFil).Results(nData-1,8)) > pi/2
       Filament(nFil).Data{nData} = flipud(Filament(nFil).Data{nData});
       Filament(nFil).Results(nData,8) = single( mod(Filament(nFil).Results(nData,8)+pi,2*pi) );
    end
elseif nData == 1 && size(Filament(nFil).Results,1) > 1
    if abs(Filament(nFil).Results(nData,8)-Filament(nFil).Results(nData+1,8))>pi/2
       Filament(nFil).Data{nData} = flipud(Filament(nFil).Data{nData});
       Filament(nFil).Results(nData,8) = single( mod(Filament(nFil).Results(nData,8)+pi,2*pi) );
    end
end

Filament(nFil).PosStart(nData,1:2) = Filament(nFil).Data{nData}(1,1:2);
Filament(nFil).PosCenter(nData,1:2) = Filament(nFil).Results(nData,3:4);
Filament(nFil).PosEnd(nData,1:2) = Filament(nFil).Data{nData}(end,1:2);



