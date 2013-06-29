function fManualTrack(Stack,StackInfo,Config,StatusNr,Objects)
global pic;
global error_events;
if ~exist( 'error_events', 'var' ) || isempty( error_events )
  error_events = struct( ...
  'touching_border',     0, 'cluster_cod_low', 0, 'endpoint_cod_low', 0, ...
  'middlepoint_cod_low', 0, 'bead_cod_low',    0, 'fil_cod_low',       0, ...
  'degenerated_fil',      0, 'empty_object',    0, 'point_not_fitted', 0, ...
  'found_wrong_type',    0, 'object_too_dark', 0, 'fit_hit_bounds',   0, ...
  'fit_impossible',      0, 'area_too_small' , 0 ...
);
end
  
DirRoot = [fileparts( mfilename('fullpath') ) filesep];

found=0;

params.bead_model=Config.Model;
params.max_beads_per_region=Config.MaxFunc;
params.scale=Config.PixSize;
params.ridge_model = 'quadratic';

params.find_molecules=0;
params.find_beads=1;

params.area_threshold=Config.Threshold.Area;
params.height_threshold=Config.Threshold.Height;   
params.fwhm_estimate=Config.Threshold.FWHM;
params.min_cod=Config.Threshold.Fit;
params.binary_image_processing=Config.Threshold.Filter;

if strcmp( params.bead_model, 'GaussSymmetric' )
    params.bead_model_char = 'p';
  elseif strcmp( params.bead_model, 'GaussStreched' )
    params.bead_model_char = 'b';
  elseif strcmp( params.bead_model, 'GaussPlusRing' )
    params.bead_model_char = 'r';
  elseif strcmp( params.bead_model, 'GaussPlus2Rings' )
    params.bead_model_char = 'f';    
end

params.fwhm_estimate = params.fwhm_estimate / params.scale; 

params.object_width = sqrt( log(4) ) * params.fwhm_estimate;

params.fit_size = 2.5 * params.object_width;
params.display = 0;

guess = struct( 'model', {}, 'obj', {}, 'idx', {}, 'x', {}, 'o', {}, 'r', {}, 'w', {}, 'h', {});
bead_model_char=params.bead_model_char;
guess(1).idx = 1;   
b='';
hMainGui=getappdata(0,'hMainGui');
if Config.FirstTFrame>0
    n=Config.FirstTFrame;
    while n<=min([Config.LastFrame length(Stack)])
        pic=double(Stack{n});
        params.creation_time=(StackInfo.CreationTime(n)-StackInfo.CreationTime(1))/1000;
        hMainGui.Values.FrameIdx=n;
        setappdata(0,'hMainGui',hMainGui);
        fShow('Image');   
        set(hMainGui.MidPanel.eFrame,'String',int2str(hMainGui.Values.FrameIdx));
        set(hMainGui.MidPanel.sFrame,'Value',hMainGui.Values.FrameIdx);
        drawnow;
        if found==0
            x = ginput(1);
            if isempty(x)
                n=min([Config.LastFrame length(Stack)])+1;
            end
            Track = [];
        else
            Track = [Track; double(data.x)]; %#ok<AGROW>
            nTrack = size(Track,1);
            if nTrack > 1
                x = Track(nTrack,:) + (Track(nTrack,:) - Track(nTrack-1,:));
            else
                x = Track;
            end
        end
        try
            guess(1).model = bead_model_char;
            [params,guess,b] = GetCoeff(x,params,guess,bead_model_char);
            guess(1).model = b;            
            params.bead_model_char = b;
        catch
            n=min([Config.LastFrame length(Stack)])+1;
        end
        params.bead_model_char=bead_model_char;
        if n<=min([Config.LastFrame length(Stack)])
            try
                [ data, CoD ] = Fit2D( b, guess, params );
            catch
                CoD = -Inf;
            end
            if CoD<params.min_cod
                button = questdlg('No Object found - How to proceed?','FIESTA Manual Tracking','Skip','Retry','Abort','Skip');
                if strcmp(button,'Skip');
                    n=n+1;
                elseif strcmp(button,'Abort')
                    n=min([Config.LastFrame length(Stack)])+1;
                end
                found=0;
            else
                obj(1).p(1) = data;
                obj = InterpolateData( obj, pic, params );
                Objects{n} = obj;
                n=n+1;
                found=1;
            end
        end
    end
end
if Config.LastFrame>length(Stack)&&Config.FirstTFrame>0
    disp(sprintf('Warning out of memory - Only tracked till frame number %4.0f',length(Stack)));
end
if ~isempty(Objects)
sObjects=Objects; %#ok<NASGU>
sConfig=Config; %#ok<NASGU>
if ~isempty(strfind(Config.StackName,'.stk'))
    sName = strrep(Config.StackName, '.stk', '');
elseif ~isempty(strfind(Config.StackName,'.tif'))
    sName = strrep(Config.StackName, '.tif', '');
else
    sName = Config.StackName;
end
try
    fData=[Config.Directory sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
    save(fData,'-v6','Objects','Config');
catch
    fData=[strrep(DirRoot,['FIESTA' filesep],'') sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
    save(fData,'-v6','Objects','Config');
end

[MolTrack,FilTrack,abort]=fFeatureConnect(Objects,Config,StatusNr);
if abort==1
    return
end
Molecule=[];
Filament=[];
Molecule=fDefStructure(Molecule,'Molecule');
Filament=fDefStructure(Filament,'Filament');

nMolTrack=length(MolTrack);
for i = 1:nMolTrack
    nData=size(MolTrack{i},1);
    Molecule(i).Selected=0;
    Molecule(i).Visible=1;    
    s=sprintf('Molecule(%d).Name=''Molecule %d'';',i,i); eval(s)
    Molecule(i).Directory=Config.Directory;
    Molecule(i).File=Config.StackName;
    Molecule(i).Color=[0 0 1];
    Molecule(i).Drift=0;    
    for j = 1:nData
        Molecule(i).Results(j,1) = MolTrack{i}(j,1);
        Molecule(i).Results(j,2) = Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).time;
        Molecule(i).Results(j,3) = Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).center_x;
        Molecule(i).Results(j,4) = Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).center_y;
        Molecule(i).Results(j,5) = norm([Molecule(i).Results(j,3)-Molecule(i).Results(1,3) Molecule(i).Results(j,4)-Molecule(i).Results(1,4)]);
        %determine what kind of Molecule found
        nHeight = length(Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).height);
        if length(double(Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).width))==1 || nHeight>1
            %Symmetric
            Molecule(i).Results(j,6)=double(Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).width(1));
        else
            %Streched
            Molecule(i).Results(j,6)=mean(double(Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).width(1:2)));
        end
        Molecule(i).Results(j,7)=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).height(1);                
        Molecule(i).Results(j,8)=sqrt((Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).center_x.error)^2+...
                                      (Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).center_y.error)^2);
        if nHeight>1
            Molecule(i).Results(j,9)=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).radius(2);                
            Molecule(i).Results(j,10)=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).width(2);                            
            Molecule(i).Results(j,11)=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).height(2);                                        
            if nHeight>2
                Molecule(i).Results(j,12)=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).radius(3);                
                Molecule(i).Results(j,13)=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).width(3);                            
                Molecule(i).Results(j,14)=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).height(3);                                                        
            end
        end
        Molecule(i).data{j}=Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).data;
        Molecule(i).data{j}.w=double(Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).width);
        Molecule(i).data{j}.h=double(Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).height);
        Molecule(i).data{j}.r=double(Objects{MolTrack{i}(j,1)}(MolTrack{i}(j,2)).radius);        
    end
end

nFilTrack=length(FilTrack);
for i=1:nFilTrack
    nData=size(FilTrack{i},1);
    Filament(i).Selected=0;
 	Filament(i).Visible=1;    
    s=sprintf('Filament(%d).Name=''Filament %d'';',i,i); eval(s)
    Filament(i).Directory=Config.Directory;
    Filament(i).File=Config.StackName;
    Filament(i).Color=[0 0 1];
    Filament(i).Drift=0;
    for j=1:nData
        Filament(i).ResultsCenter(j,1)=FilTrack{i}(j,1);
        Filament(i).ResultsCenter(j,2)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).time;
        Filament(i).ResultsCenter(j,3)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).center_x;
        Filament(i).ResultsCenter(j,4)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).center_y;
        Filament(i).ResultsCenter(j,5)=norm([Filament(i).ResultsCenter(j,3)-Filament(i).ResultsCenter(1,3) Filament(i).ResultsCenter(j,4)-Filament(i).ResultsCenter(1,4)]);
        Filament(i).ResultsCenter(j,6)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).length;
        Filament(i).ResultsCenter(j,7)=double([Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).height]);
        Filament(i).ResultsCenter(j,8)=1;
        Filament(i).data{j}=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).data;
        Filament(i).Orientation(j)=mod(double(Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).orientation),2*pi);
        if j>1
            d=sqrt( (Filament(i).data{j}(1).x-Filament(i).data{j-1}(1).x)^2 +...
                    (Filament(i).data{j}(1).y-Filament(i).data{j-1}(1).y)^2);
            if d>Filament(i).ResultsCenter(j,6)/2
               Filament(i).data{j}=Filament(i).data{j}(length(Filament(i).data{j}):-1:1);
               Filament(i).Orientation(j)=mod(Filament(i).Orientation(j)+pi,2*pi);
            end
        end
        Filament(i).ResultsStart(j,1)=FilTrack{i}(j,1);
        Filament(i).ResultsStart(j,2)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).time;
        Filament(i).ResultsStart(j,3)=Filament(i).data{j}(1).x;
        Filament(i).ResultsStart(j,4)=Filament(i).data{j}(1).y;
        Filament(i).ResultsStart(j,5)=norm([Filament(i).ResultsStart(j,3)-Filament(i).ResultsStart(1,3) Filament(i).ResultsStart(j,4)-Filament(i).ResultsStart(1,4)]);
        Filament(i).ResultsStart(j,6)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).length;
        Filament(i).ResultsStart(j,7)=Filament(i).data{j}(1).h;
        Filament(i).ResultsStart(j,8)=1;
                                          
        END=length(Filament(i).data{j});
        Filament(i).ResultsEnd(j,1)=FilTrack{i}(j,1);
        Filament(i).ResultsEnd(j,2)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).time;
        Filament(i).ResultsEnd(j,3)=Filament(i).data{j}(END).x;
        Filament(i).ResultsEnd(j,4)=Filament(i).data{j}(END).y;
        Filament(i).ResultsEnd(j,5)=norm([Filament(i).ResultsEnd(j,3)-Filament(i).ResultsEnd(1,3) Filament(i).ResultsEnd(j,4)-Filament(i).ResultsEnd(1,4)]);
        Filament(i).ResultsEnd(j,6)=Objects{FilTrack{i}(j,1)}(FilTrack{i}(j,2)).length;
        Filament(i).ResultsEnd(j,7)=Filament(i).data{j}(END).h;
        Filament(i).ResultsEnd(j,8)=1;
    end
end
try
    save(fData,'-append','-v6','Molecule','Filament');
catch
    fData=[strrep(DirRoot,['FIESTA' filesep],'') sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
    save(fData,'-v6','Molecule','Filament','Objects');
    disp('Directory not accessible - File saved in FIESTA root directory');
end
end


function [GMAX,GMIN]=CorrectGrad(XMAX,GMAX,XMIN,GMIN)
GMAX( XMAX < 0 ) = [];
GMIN( XMIN > 0 ) = [];
GMIN=sort(GMIN);
GMAX=sort(GMAX);
pmax=1;
pmin=1;
while pmax<length(GMAX) && pmin<length(GMIN)
    if GMAX(pmax)<GMIN(pmin)
        k = find(GMAX>GMAX(pmax) & GMAX<GMIN(pmin));
        if ~isempty(k)
            GMAX(pmax)=mean([GMAX(pmax); GMAX(k)]);
            GMAX(k)=[];
        end
        pmax=pmax+1;
    elseif GMAX(pmax)>GMIN(pmin)
        k = find(GMIN>GMIN(pmin) & GMIN<GMAX(pmax));
        if ~isempty(k)
            GMIN(pmin)=mean([GMIN(pmin); GMIN(k)]);
            GMIN(k)=[];
        end
        pmin=pmin+1;
    end
end

function [params,guess,b] = GetCoeff(x,params,guess,b)
[I,data] = GetImage(params,x);
[X,Y]=meshgrid(1:size(I,2),1:size(I,1));
[center_x,center_y] = cmass(I,X,Y);

[I,data] = GetImage(params,double(data.offset) + [center_x center_y]);
[X,Y]=meshgrid(1:size(I,2),1:size(I,1));
[center_x,center_y] = cmass(I,X,Y);

[XMAX,IMAX,XMIN,IMIN] = extrema(smooth(double(I(round(center_y),:)),3));
[XMAX,GMAX,XMIN,GMIN] = extrema(smooth(gradient(smooth(double(I(round(center_y),:)),3)),3));
[GMAX,GMIN]=CorrectGrad(XMAX,GMAX,XMIN,GMIN);
[r1x,r2x,w1x,w2x,w3x] = GetRing(IMAX,IMIN,GMAX,GMIN,center_x);

[XMAX,IMAX,XMIN,IMIN] = extrema(smooth(double(I(:,round(center_x))),3));
[XMAX,GMAX,XMIN,GMIN] = extrema(smooth(gradient(smooth(double(I(:,round(center_x))),3)),3));
[GMAX,GMIN]=CorrectGrad(XMAX,GMAX,XMIN,GMIN);
[r1y,r2y,w1y,w2y,w3y] = GetRing(IMAX,IMIN,GMAX,GMIN,center_y);

r2 = mean([r2x r2y]);

rh = [r1x r1y];
if isempty(rh)
    r1=0;
else
    rh( rh >r2 ) = [];
    r1 = mean(rh);
end

w1 = [w1x w1y];
if ~isempty(w1)
    w1 = mean(w1);
else
    w1 = 10;
end
w2 = mean([w2x w2y]);
w3 = mean([w3x w3y]);

%get vextor for interpolation
%center
XI = center_x;
YI = center_y;
%first ring
XI = [XI center_x+r1*cos(2*pi/100:2*pi/100:2*pi)];
YI = [YI center_y+r1*sin(2*pi/100:2*pi/100:2*pi)];
%second ring
XI = [XI center_x+r2*cos(2*pi/100:2*pi/100:2*pi)];
YI = [YI center_y+r2*sin(2*pi/100:2*pi/100:2*pi)];

rmax = min([1.5*r2 center_x-1 center_y-1 size(I,1)-center_y size(I,2)-center_x]);
%third ring for background
XI = [XI center_x+rmax*cos(2*pi/100:2*pi/100:2*pi)];
YI = [YI center_y+rmax*sin(2*pi/100:2*pi/100:2*pi)];

values = interp2(X,Y,I,XI,YI);

guess.x = double(data.offset) + [center_x center_y];
guess.r = [0 r1 r2];
guess.w = [w1 w2 w3];
params.background = mean(values(202:301));
if r1==0
    guess.h = [params.background-values(1) 2*(mean(values(102:201))-params.background)];
    guess.r = [0 r2];
    guess.w = [w1 w3];
    b='n';
else
    guess.h = [values(1)-mean(values(2:101)) params.background-mean(values(2:101)) 2*(mean(values(102:201))-params.background)];
end
if guess.h(1) < 0 
    guess.r = [0 r2];
    guess.w = [w1 w3];
    guess.h = [params.background-values(1) 2*(mean(values(102:201))-params.background)];    
    b='n';
end

function [r1,r2,w1,w2,w3]=GetRing(IMAX,IMIN,GMAX,GMIN,x)
Dir=(IMIN(1)-x)/abs(IMIN(1)-x);
if Dir==-1
    LeftMin = IMIN(1);
    GradLeft = GMAX(find( GMAX > LeftMin ,1,'first'));
    GradRight = GMIN(find( GMIN > GradLeft ,1,'first'));        
    RightMin = IMIN(find( IMIN > GradRight ,1,'first'));    
else
    RightMin = IMIN(1);
    GradRight = GMIN(find( GMIN < RightMin ,1,'last'));
    GradLeft = GMAX(find( GMAX < GradRight ,1,'last'));
    LeftMin = IMIN(find( IMIN < GradLeft ,1,'first'));        
end
k = find( IMAX >= GradLeft & IMAX <= GradRight, 1,'first' );
CenterMax = IMAX(k);
if abs(CenterMax-x)<4
    r1 = [CenterMax-LeftMin RightMin-CenterMax];
    w1 = (GradRight-GradLeft)^2 / 2.77258872223978;
else
    CenterMax=IMIN(1);
    LeftMin = CenterMax-1;
    RightMin = CenterMax+1;    
    GradLeft = GMIN(find( GMIN < LeftMin ,1,'last'));
    GradRight = GMAX(find( GMAX > RightMin ,1,'first'));    
    r1 = [];
    w1 = (GradLeft-GradRight).^2 / 2.77258872223978;
    w2 = [];
end
IMAX=sort(IMAX);
GradLeft = GMIN(find( GMIN < LeftMin ,1,'last'));
k = find( IMAX < GradLeft ,1,'last');
if ~isempty(k)
    r2(1) = CenterMax - IMAX(k);
    w2(1) = (CenterMax-GradLeft)^2 / 2.77258872223978;
    w3(1) = (LeftMin - IMAX(k))^2 / 2.77258872223978;
end
GradRight = GMAX(find( GMAX > RightMin ,1,'first'));    
k = find( IMAX > GradRight ,1,'first');
if ~isempty(k)
    r2(2)= IMAX(k) - CenterMax;
    w2(2) = (GradRight - CenterMax)^2 / 2.77258872223978;    
    w3(2) = (IMAX(k) - RightMin)^2 / 2.77258872223978;
end
r2(r2==0) = [];

function [meanx,meany]=cmass(I,X,Y)
I=abs(double(I)-double(mean2(I)));
I=I-0.5*(max(max(I))-min(min(I)));
I(I<0)=0;
area = sum(sum(I));
meanx = sum(sum(double(I).*X))/area;
meany = sum(sum(double(I).*Y))/area;

function [I,data]=GetImage(params,x)
global pic;
tl = x - params.fit_size;
br = x + params.fit_size;
  
tl( tl < 1 ) = 1; % top and left side
if br(1) > size( pic, 2 ) % bottom side
    br(1) = size( pic, 2 );
end
if br(2) > size( pic, 1 ) % right side
    br(2) = size( pic, 1 );
end

data = struct( 'rect', [ round(tl)  round(br)-round(tl) ] ); 
data.offset = data.rect(1:2) - 1; %<< offset between the original and the cropped image

I = imcrop( pic, data.rect ); %<< create cropped image