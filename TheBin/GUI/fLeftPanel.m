function varargout=fLeftPanel(func,varargin)
varargout={};
switch func
    case 'NormPanel'
        NormPanel(varargin{1});        
    case 'ThreshPanel'
        ThreshPanel(varargin{1});
    case 'RedNormPanel'
        RedNormPanel(varargin{1});
    case 'GreenNormPanel'
        GreenNormPanel(varargin{1});        
    case 'RedThreshPanel'
        RedThreshPanel(varargin{1});
    case 'GreenThreshPanel'
        GreenThreshPanel(varargin{1});                
    case 'sScaleMin'
        sScaleMin(varargin{1});
    case 'sScaleMax'
        sScaleMax(varargin{1});
    case 'sScale'
        sScale(varargin{1});
    case 'eScaleMin'
        eScaleMin(varargin{1});
    case 'eScaleMax'
        eScaleMax(varargin{1});
    case 'eScale'
        eScale(varargin{1});
    case 'LoadRegion'
        LoadRegion(varargin{1});
    case 'SaveRegion'
        SaveRegion(varargin{1});
    case 'CheckRegion'
        CheckRegion(varargin{1});       
    case 'SetThresh'
        SetThresh(varargin{1},varargin{2});       
    case 'DisableAllPanels'
        DisableAllPanels(varargin{1});           
    case 'RegUpdateList'
        RegUpdateList(varargin{1});
    case 'RegListSlider'
        RegListSlider(varargin{1}); 
end

function SetThresh(hMainGui,Mode)
global Stack;
sPanels{1}='';
sPanels{2}='Red';
sPanels{3}='Green';
for n=1:3
    if isempty(Stack)||strcmp(Mode,'variable')
        enable='off';
        Max=2;
        Thresh=1;
        sStep=1;
        visible='off';
        strThresh='';
    else
        enable='on';
        if strcmp(Mode,'constant')
            Max=hMainGui.Values.(sprintf('Pix%sMax',sPanels{n}));
            Thresh=hMainGui.Values.(sprintf('%sThresh',sPanels{n}));
            sStep=100;
            visible='off';
        else
            Max=hMainGui.Values.(sprintf('Max%sRelThresh',sPanels{n}));
            Thresh=hMainGui.Values.(sprintf('%sRelThresh',sPanels{n}));
            sStep=10;    
            visible='on';        
        end
        strThresh=int2str(Thresh);
    end
    slider_step(1) = 1/double(Max);
    slider_step(2) = sStep/double(Max);
    if (max(slider_step)>=1)||(min(slider_step)<=0)
        slider_step=[0.1 0.1];
    end
    panel=sprintf('p%sThresh',sPanels{n});
    set(hMainGui.LeftPanel.(panel).sScale,'Enable',enable,'sliderstep',slider_step,'max',Max,'min',1,'Value',Thresh);
    set(hMainGui.LeftPanel.(panel).eScale,'Enable',enable,'String',strThresh);
    set(hMainGui.LeftPanel.(panel).tPercent,'Visible',visible);
end

function UpdateKymo(hMainGui)
if ~isempty(hMainGui.KymoImage)
    Image=(hMainGui.KymoImage-hMainGui.Values.ScaleMin)/(hMainGui.Values.ScaleMax-hMainGui.Values.ScaleMin);
    Image(Image<0)=0;
    Image(Image>1)=1;
    Image=Image*2^16;
    set(hMainGui.KymoGraph,'CData',Image);
end

function sScaleMin(hMainGui)
h=gcbo;
value=round(get(h,'Value'));
if strcmp(get(hMainGui.LeftPanel.pNorm.panel,'Visible'),'on')==1
    if value<hMainGui.Values.ScaleMax
        hMainGui.Values.ScaleMin=value;
    else
        hMainGui.Values.ScaleMin=hMainGui.Values.ScaleMax;
    end
    UpdateKymo(hMainGui);
elseif strcmp(get(hMainGui.LeftPanel.pRedNorm.panel,'Visible'),'on')==1
    if value<hMainGui.Values.ScaleRedMax
        hMainGui.Values.ScaleRedMin=value;
    else
        hMainGui.Values.ScaleRedMin=hMainGui.Values.ScaleRedMax;     
    end
else
    if value<hMainGui.Values.ScaleGreenMax
        hMainGui.Values.ScaleGreenMin=value;
    else
        hMainGui.Values.ScaleGreenMin=hMainGui.Values.ScaleGreenMax;           
    end
end
setappdata(0,'hMainGui',hMainGui);
Update(hMainGui);

function sScaleMax(hMainGui)
h=gcbo;
value=round(get(h,'Value'));
if strcmp(get(hMainGui.LeftPanel.pNorm.panel,'Visible'),'on')==1
    if value>hMainGui.Values.ScaleMin    
        hMainGui.Values.ScaleMax=value;
    else
        hMainGui.Values.ScaleMax=hMainGui.Values.ScaleMin;        
    end
    UpdateKymo(hMainGui);
elseif strcmp(get(hMainGui.LeftPanel.pRedNorm.panel,'Visible'),'on')==1
    if value>hMainGui.Values.ScaleRedMin    
        hMainGui.Values.ScaleRedMax=value;
    else
        hMainGui.Values.ScaleRedMax=hMainGui.Values.ScaleRedMin;        
    end
else
    if value>hMainGui.Values.ScaleGreenMin    
        hMainGui.Values.ScaleGreenMax=value;
    else
        hMainGui.Values.ScaleGreenMax=hMainGui.Values.ScaleGreenMin;  
    end
end
setappdata(0,'hMainGui',hMainGui);
Update(hMainGui);

function sScale(hMainGui)
global Config
h=gcbo;
value=round(get(h,'Value'));
if strcmp(Config.Threshold.Mode,'constant')==1
    if strcmp(get(hMainGui.LeftPanel.pThresh.panel,'Visible'),'on')==1
        hMainGui.Values.Thresh=value;
    elseif strcmp(get(hMainGui.LeftPanel.pRedThresh.panel,'Visible'),'on')==1
        hMainGui.Values.RedThresh=value;
    else
        hMainGui.Values.GreenThresh=value;
    end
elseif strcmp(Config.Threshold.Mode,'relative')==1
    if strcmp(get(hMainGui.LeftPanel.pThresh.panel,'Visible'),'on')==1
        hMainGui.Values.RelThresh=value;
    elseif strcmp(get(hMainGui.LeftPanel.pRedThresh.panel,'Visible'),'on')==1
        hMainGui.Values.RedRelThresh=value;
    else
        hMainGui.Values.GreenRelThresh=value;
    end
end
setappdata(0,'hMainGui',hMainGui);
Update(hMainGui);

function eScaleMin(hMainGui)
h=gcbo;
value=round(str2double(get(h,'String')));
if value<1
    value=1;
end
if ~isnan(value)
    if strcmp(get(hMainGui.LeftPanel.pNorm.panel,'Visible'),'on')==1
        if value<hMainGui.Values.ScaleMax
            hMainGui.Values.ScaleMin=value;
        else
            hMainGui.Values.ScaleMin=hMainGui.Values.ScaleMax;
        end
        UpdateKymo(hMainGui);
    elseif strcmp(get(hMainGui.LeftPanel.pRedNorm.panel,'Visible'),'on')==1
        if value<hMainGui.Values.ScaleRedMax
            hMainGui.Values.ScaleRedMin=value;
        else
            hMainGui.Values.ScaleRedMin=hMainGui.Values.ScaleRedMax;     
        end
    else
        if value<hMainGui.Values.ScaleGreenMax
            hMainGui.Values.ScaleGreenMin=value;
        else
            hMainGui.Values.ScaleGreenMin=hMainGui.Values.ScaleGreenMax;           
        end
    end
end
setappdata(0,'hMainGui',hMainGui);
Update(hMainGui);


function eScaleMax(hMainGui)
h=gcbo;
value=round(str2double(get(h,'String')));
if ~isnan(value)
    if strcmp(get(hMainGui.LeftPanel.pNorm.panel,'Visible'),'on')==1
        if value>hMainGui.Values.PixMax
            value=hMainGui.Values.PixMax;
        end
        if value>hMainGui.Values.ScaleMin    
            hMainGui.Values.ScaleMax=value;
        else
            hMainGui.Values.ScaleMax=hMainGui.Values.ScaleMin;        
        end
        UpdateKymo(hMainGui);
    elseif strcmp(get(hMainGui.LeftPanel.pRedNorm.panel,'Visible'),'on')==1
        if value>hMainGui.Values.PixRedMax
            value=hMainGui.Values.PixRedMax;
        end
        if value>hMainGui.Values.ScaleRedMin    
            hMainGui.Values.ScaleRedMax=value;
        else
            hMainGui.Values.ScaleRedMax=hMainGui.Values.ScaleRedMin;        
        end
    else
        if value>hMainGui.Values.PixGreenMax
            value=hMainGui.Values.PixGreenMax;
        end
        if value>hMainGui.Values.ScaleGreenMin    
            hMainGui.Values.ScaleGreenMax=value;
        else
            hMainGui.Values.ScaleGreenMax=hMainGui.Values.ScaleGreenMin;  
        end
    end
end
setappdata(0,'hMainGui',hMainGui);
Update(hMainGui);

function eScale(hMainGui)
global Config;
h=gcbo;
value=round(str2double(get(h,'String')));
if ~isnan(value);
    if value<1
        value=1;
    end
    if strcmp(Config.Threshold.Mode,'constant')==1
        if strcmp(get(hMainGui.LeftPanel.pThresh.panel,'Visible'),'on')==1
            if value>hMainGui.Values.PixMax
                 value=hMainGui.Values.PixMax;
            end
            hMainGui.Values.Thresh=value;
        elseif strcmp(get(hMainGui.LeftPanel.pRedThresh.panel,'Visible'),'on')==1
            if value>hMainGui.Values.PixRedMax
                 value=hMainGui.Values.PixRedMax;
            end
            hMainGui.Values.RedThresh=value;
        else
            if value>hMainGui.Values.PixGreenMax
                 value=hMainGui.Values.PixGreenMax;
            end
            hMainGui.Values.GreenThresh=value;
        end
    elseif strcmp(Config.Threshold.Mode,'relative')==1
        if strcmp(get(hMainGui.LeftPanel.pThresh.panel,'Visible'),'on')==1
            if value>hMainGui.Values.MaxRelThresh
                 value=hMainGui.Values.MaxRelThresh;
            end
            hMainGui.Values.RelThresh=value;
        elseif strcmp(get(hMainGui.LeftPanel.pRedThresh.panel,'Visible'),'on')==1
            if value>hMainGui.Values.MaxRedRelThresh
                 value=hMainGui.Values.MaxRedRelThresh;
            end
            hMainGui.Values.RedRelThresh=value;
        else
            if value>hMainGui.Values.MaxGreenRelThresh
                 value=hMainGui.Values.MaxGreenRelThresh;
            end
            hMainGui.Values.GreenRelThresh=value;
        end
    end
end
setappdata(0,'hMainGui',hMainGui);
Update(hMainGui);

function Update(hMainGui)
global Config;
set(hMainGui.LeftPanel.pNorm.sScaleMin,'Value',hMainGui.Values.ScaleMin);
set(hMainGui.LeftPanel.pNorm.sScaleMax,'Value',hMainGui.Values.ScaleMax);
set(hMainGui.LeftPanel.pNorm.eScaleMin,'String',int2str(hMainGui.Values.ScaleMin));
set(hMainGui.LeftPanel.pNorm.eScaleMax,'String',int2str(hMainGui.Values.ScaleMax));
set(hMainGui.LeftPanel.pRedNorm.sScaleMin,'Value',hMainGui.Values.ScaleRedMin);
set(hMainGui.LeftPanel.pRedNorm.sScaleMax,'Value',hMainGui.Values.ScaleRedMax);
set(hMainGui.LeftPanel.pRedNorm.eScaleMin,'String',int2str(hMainGui.Values.ScaleRedMin));
set(hMainGui.LeftPanel.pRedNorm.eScaleMax,'String',int2str(hMainGui.Values.ScaleRedMax));
set(hMainGui.LeftPanel.pGreenNorm.sScaleMin,'Value',hMainGui.Values.ScaleGreenMin);
set(hMainGui.LeftPanel.pGreenNorm.sScaleMax,'Value',hMainGui.Values.ScaleGreenMax);
set(hMainGui.LeftPanel.pGreenNorm.eScaleMin,'String',int2str(hMainGui.Values.ScaleGreenMin));
set(hMainGui.LeftPanel.pGreenNorm.eScaleMax,'String',int2str(hMainGui.Values.ScaleGreenMax));
if strcmp(Config.Threshold.Mode,'constant')==1
    set(hMainGui.LeftPanel.pThresh.sScale,'Value',hMainGui.Values.Thresh);    
    set(hMainGui.LeftPanel.pThresh.eScale,'String',int2str(hMainGui.Values.Thresh));
    set(hMainGui.LeftPanel.pRedThresh.sScale,'Value',hMainGui.Values.RedThresh);
    set(hMainGui.LeftPanel.pRedThresh.eScale,'String',int2str(hMainGui.Values.RedThresh));
    set(hMainGui.LeftPanel.pGreenThresh.sScale,'Value',hMainGui.Values.GreenThresh);
    set(hMainGui.LeftPanel.pGreenThresh.eScale,'String',int2str(hMainGui.Values.GreenThresh));
elseif strcmp(Config.Threshold.Mode,'relative')==1
    set(hMainGui.LeftPanel.pThresh.sScale,'Value',hMainGui.Values.RelThresh);    
    set(hMainGui.LeftPanel.pThresh.eScale,'String',int2str(hMainGui.Values.RelThresh));
    set(hMainGui.LeftPanel.pRedThresh.sScale,'Value',hMainGui.Values.RedRelThresh);
    set(hMainGui.LeftPanel.pRedThresh.eScale,'String',int2str(hMainGui.Values.RedRelThresh));
    set(hMainGui.LeftPanel.pGreenThresh.sScale,'Value',hMainGui.Values.GreenRelThresh);
    set(hMainGui.LeftPanel.pGreenThresh.eScale,'String',int2str(hMainGui.Values.GreenRelThresh));
end
fShared('ReturnFocus');
fShow('Image');

function SetAllPanelsOff(hMainGui)
global Config;
set(hMainGui.LeftPanel.pNorm.panel,'Visible','off');
set(hMainGui.LeftPanel.pThresh.panel,'Visible','off');
set(hMainGui.LeftPanel.pRedNorm.panel,'Visible','off');
set(hMainGui.LeftPanel.pGreenNorm.panel,'Visible','off');
set(hMainGui.LeftPanel.pRedThresh.panel,'Visible','off');
set(hMainGui.LeftPanel.pGreenThresh.panel,'Visible','off');
SetThresh(hMainGui,Config.Threshold.Mode);

function DisableAllPanels(hMainGui)
sPanels{1}='';
sPanels{2}='Red';
sPanels{3}='Green';
for n=1:3
    set(findobj('Parent',hMainGui.LeftPanel.(sprintf('p%sNorm',sPanels{n})).panel,'-and','Style','edit'),'Enable','off');
    set(findobj('Parent',hMainGui.LeftPanel.(sprintf('p%sThresh',sPanels{n})).panel,'-and','Style','edit'),'Enable','off');    
    set(findobj('Parent',hMainGui.LeftPanel.(sprintf('p%sNorm',sPanels{n})).panel,'-and','Type','slider'),'Enable','off');
    set(findobj('Parent',hMainGui.LeftPanel.(sprintf('p%sThresh',sPanels{n})).panel,'-and','Style','slider'),'Enable','off');    
    cla(hMainGui.LeftPanel.(sprintf('p%sNorm',sPanels{n})).aScaleBar);
    cla(hMainGui.LeftPanel.(sprintf('p%sThresh',sPanels{n})).aScaleBar);        
end

function NormPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.LeftPanel.pNorm.panel,'Visible','on');
if isfield(hMainGui,'Values')
    fShow('Image');
    fShow('Tracks');
end

function ThreshPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.LeftPanel.pThresh.panel,'Visible','on');
if isfield(hMainGui,'Values')
    fShow('Image');
    fShow('Tracks');    
end

function RedNormPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.LeftPanel.pRedNorm.panel,'Visible','on');
if isfield(hMainGui,'Values')
    fShow('Image');
    fShow('Tracks');    
end

function GreenNormPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.LeftPanel.pGreenNorm.panel,'Visible','on');
if isfield(hMainGui,'Values')
    fShow('Image');
    fShow('Tracks');    
end

function RedThreshPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.LeftPanel.pRedThresh.panel,'Visible','on');
if isfield(hMainGui,'Values')
    fShow('Image');
    fShow('Tracks');    
end

function GreenThreshPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.LeftPanel.pGreenThresh.panel,'Visible','on');
if isfield(hMainGui,'Values')
    fShow('Image');
    fShow('Tracks');    
end

function RegUpdateList(hMainGui)
l = length(hMainGui.Region);
slider = hMainGui.LeftPanel.pRegions.sRegList;
if l>8
    slider_step(1) = 1/(l-8);
    slider_step(2) = 8/(l-8);
    if strcmp(get(slider,'Enable'),'on')==1
        v=get(slider,'Value');
        if v>l-7
            v=l-7;
        end
        set(slider,'sliderstep',slider_step,...
         'max',l-7,'min',1,'Value',v)
    else
        set(slider,'sliderstep',slider_step,...
         'max',l-7,'min',1,'Value',l-8,'Enable','on')
    end
    ListBegin=(l-7)-round(get(slider,'Value'));
    ListLength=8;
else
    slider_step(1) = 0.1;
    slider_step(2) = 0.1;
    set(slider,'sliderstep',slider_step,...
         'max',2,'min',1,'Value',1,'Enable','off')
     ListLength=l;
     ListBegin=0;
end
for i=1:ListLength
    set(hMainGui.LeftPanel.pRegions.RegList.Pan(i),'Visible','on','UIContextMenu',hMainGui.Menu.ctRegion);    
    set(hMainGui.LeftPanel.pRegions.RegList.Region(i),'Enable','inactive','ForegroundColor',hMainGui.Region(i+ListBegin).color,'UIContextMenu',hMainGui.Menu.ctRegion,'String',['Region ' num2str(i+ListBegin)],'UserData',i+ListBegin);
end
for i=ListLength+1:8
    set(hMainGui.LeftPanel.pRegions.RegList.Pan(i),'Visible','off');    
    set(hMainGui.LeftPanel.pRegions.RegList.Region(i),'Enable','off','String','');
end
if l>0
    set(hMainGui.LeftPanel.pRegions.cExcludeReg,'Enable','on');
else
    set(hMainGui.LeftPanel.pRegions.cExcludeReg,'Enable','off');
end

function RegListSlider(hMainGui)
RegUpdateList(hMainGui);
fShared('ReturnFocus');

function LoadRegion(hMainGui)
[FileName, PathName] = uigetfile({'*.mat','FIESTA Regions (*.mat)'},'Load FIESTA Regions',fShared('GetLoadDir'));
if FileName~=0
    fShared('SetLoadDir',PathName);
    Region=fLoad([PathName FileName],'Region');
    nRegion=length(hMainGui.Region);
    nNewRegion=length(Region);
    hMainGui.Region = [hMainGui.Region Region];
    for i=nRegion+1:nRegion+nNewRegion
        hMainGui.Region(i).color=hMainGui.RegionColor(mod(i-1,24)+1,:);        
        hMainGui.Plots.Region(i)=plot(hMainGui.Region(i).X,hMainGui.Region(i).Y,'Color',hMainGui.Region(i).color,'LineStyle','--','UserData',i,'UIContextMenu',hMainGui.Menu.ctRegion);
    end
end
setappdata(0,'hMainGui',hMainGui);
RegUpdateList(hMainGui);
fShared('ReturnFocus');

function SaveRegion(hMainGui)
[FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Regions',fShared('GetSaveDir'));
if FileName~=0
    fShared('SetSaveDir',PathName);
    Region=hMainGui.Region; %#ok<NASGU>
    file = [PathName FileName];
    if isempty(findstr('.mat',file))
        file = [file '.mat'];
    end
    save(file,'Region');
end
fShared('ReturnFocus');