function [ objects, params ] = RoughScan( params )
%ROUGHSCAN tries to locates objects roughly. This is done using a thresholded
%(black and white) image and some image processing. The results are inaccurate
%position coordinates for points and a list of coordinates for elongated
%objects, roughly descibing the spatial configuration in the image.
%
% arguments:
%   objects   the objects array
%   params    the parameter struct
% results:
%   objects   the extended objects array

  error( nargchk( 1, 1, nargin ) );

  % images are global for speed
  global pic; %<< load image from global variable
  global bw;  %<< set thresholded image as global variable
  global error_events;  %<< global error structure
  
  %%----------------------------------------------------------------------------
  %% PREPARE IMAGES
  %%-----------------------------------------------------------------------

  Log( 'create black&white image', params );
  
  % converting imgage to black and white
  bw = Image2Binary( pic, params );
  
  % estimate background level
  params.background = mean( pic( bw == 0 ) );
  
  % choose regions to fit, if they are present
  if isfield( params, 'bw_regions' )
    bw = params.bw_regions .* bw;
  end

  % calculate estimated object width
  params.object_width = sqrt( log(4) ) * params.fwhm_estimate;

  % label distinct areas in black&white image
  bw = bwlabel( bw, 8 );
  % get statistical data of the different regions
  bw_stats = regionprops( bw, 'Area', 'BoundingBox', 'Centroid', 'Image' );  
  
  % possibly debug display
  if params.display > 1
    params.fig2 = figure();
    imshow( (0 ~= bw), [0 3] );
  end
  
  % setup struct for the final object data
  objects = struct( 'p', {} );
  
  %%----------------------------------------------------------------------------
  %% SCAN BLACK AND WHITE IMAGE
  %%----------------------------------------------------------------------------

  % determine which areas should be scanned
  if ~isfield( params, 'scanareas' )
    params.scanareas = 1:numel(bw_stats);
  end
  
  % run through all regionprobs areas
  for area = params.scanareas
    
    % disregard areas touching border, if requested
    bb = round( bw_stats(area).BoundingBox );
    if params.border_margin > 0 && ...
        ( bb(1) <= params.border_margin || bb(2) <= params.border_margin || ...
          bb(1) + bb(3) >= size( pic, 2 ) + 1 - params.border_margin || ...
          bb(2) + bb(4) >= size( pic, 1 ) + 1 - params.border_margin )
      error_events.touching_border = error_events.touching_border + 1;
      continue;
    end

    Log( sprintf( 'scan area %d', area ), params );
    
    if params.display > 1 % debug output
      figure( params.fig2 );
      text( bw_stats(area).BoundingBox(1), bw_stats(area).BoundingBox(2), ...
            sprintf( '%d \\rightarrow', area ), 'Color', 'w', 'HorizontalAlignment', 'right', 'FontSize', 9 );
%       text( bb(1)+bb(3), bb(4)+bb(2), sprintf( '\\leftarrow %d', area ), 'Color', 'w', 'HorizontalAlignment', 'left', 'FontSize', 9 );
    end

    % initialize variable containing new objects
    new_obj = [];
    
    % check, which objects are requested and try to find them
    if params.find_beads && ~params.find_molecules % look only for beads
      % take all regions into consideration!
      new_obj = FindPointObjects( bw_stats(area), params );
    elseif params.find_molecules && ~params.find_beads
      % look only for line-objects (they have to be larger then the
      % area_threshold, though)
      if bw_stats(area).Area < params.area_threshold
        % assume, that this region is not requested
        error_events.area_too_small = error_events.area_too_small + 1;
      else
        % guess it's a elongated object
        box=bw_stats(area).BoundingBox;
        new_obj = FindLineObjects( bw_stats(area), params, pic(box(2)+0.5:box(2)-0.5+box(4),box(1)+0.5:box(1)-0.5+box(3)));
      end
    elseif params.find_molecules && params.find_beads
      % look for both types and distingusih them by their area
      if bw_stats(area).Area < params.area_threshold
        % guess it's a point-like object
        new_obj = FindPointObjects( bw_stats(area), params );
      else
        % guess it's a elongated objects
        new_obj = FindLineObjects( bw_stats(area), params );
      end
    end

    if ~isempty( new_obj ) % new objects have been found
      % add found objects to list
      objects(end+1:end+numel(new_obj)) = new_obj;
    end
    
  end % of loop through all regionprob objects
  
  %%----------------------------------------------------------------------------
  %% CHECK OBJECT DATA
  %%----------------------------------------------------------------------------

  % make sure, only the requested features are found
  k = 1;
  while k <= numel( objects )
    if ( ~params.find_beads && numel( objects(k).p ) < 2 ) || ...
       ( ~params.find_molecules && numel( objects(k).p ) > 1 )
      % delete wrong object
      error_events.found_wrong_type = error_events.found_wrong_type + 1;
      objects(k) = [];
    else
      k = k + 1;
    end
  end

  Log( sprintf( '%d objects found', numel(objects) ), params );

  if params.display > 1  % debug output
    for k = 1 : numel(objects)
      PlotOrientations( objects(k).p, 'r', 0.5 );
    end
  end

  % delete global variables to clean up
  clear global bw;
  
end

function objects = FindPointObjects( region_stats, params )
%FINDOBJECT tries to find beads at the given area in the bw image. This is
%achieved by looking for local maxima in the grey image corresponding to the
%region
%
% arguments:
%   region_stats  the result of the regionprobs function for the area to be
%                 scanned
%   params        the parameters struct
% results:
%   objects       a struct with the object data

  error( nargchk( 2, 2, nargin ) );

  % search local maximas in the region, to find possibly many close-lying
  % objects
  global pic %<< load grey image
  
  EMPTY_POINT = struct( 'x', {}, 'o', {}, 'w', {}, 'h', {}, 'b', {} );
  
  % crop orginal image with same dimensions as binary one
  sub_pic = imcrop( pic, region_stats.BoundingBox - [ 0 0 1 1 ] );
  sub_pic_bw = region_stats.Image;
%   sub_pic = filter2( h, sub_pic, 'same' );
%   sub_pic = medfilt2( sub_pic );

% find the local maxima area in the right area
  pic_max = imregionalmax( sub_pic .* double( sub_pic_bw ), 8 );
  % find center of the disjoint areas
  regions = regionprops( bwlabel( pic_max, 8 ), 'Centroid' );
  
  % sort maxima by there intensity
  maximas = zeros( numel(regions), 3 );
  for k = 1 : numel(regions)
    maximas(k,:) = [ regions(k).Centroid ...
        sub_pic( round( regions(k).Centroid(2) ), round( regions(k).Centroid(1) ) ) ];
  end
  maximas = sortrows( maximas, -3 );
  
  %delete maximas with ratio to brightest maximum smaller than 0.1
  if size(maximas,1)>1
    maximas((maximas(:,3)-params.background)<0.1*(maximas(1,3)-params.background),:)=[]; 
  end
  
  % choose the right maxima(s)
  if params.max_beads_per_region > 1 && size(maximas,1) > 1 % many maxima in the region    
      
    % remove maximas, which are close to each other
    idx = getClusters( maximas, 3, 2 ); % find close points
    for i = unique( idx )
      f = find( idx == i );
      maximas( f(2:end), 3 ) = -1;
    end
    maximas( maximas(:,3) < 0, : ) = [];
    
    % take the brigthes maximas
    num_maximas = min( size(maximas,1), params.max_beads_per_region );
    objects = repmat( struct( 'p', EMPTY_POINT ), 1, num_maximas ); % preallocate
    for i = 1 : num_maximas
      objects(i).p(1).x = maximas(i,1:2) + region_stats.BoundingBox(1:2) - 0.5;
    end
    
  else % only one point in region or only one point requested
    objects(1).p = EMPTY_POINT;
    objects(1).p(1).x = region_stats(1).Centroid;
  end

end

function objects = FindLineObjects( region_stats, params )
%FINDMOLECULES tries to find elongated objects or beads at the given area in the
%bw image. This is achieved using thinning the binary image to estimate the
%center line of the elongated object, where each pixel may be used as a
%coordinate for the position list of the elongated object.
%
% arguments:
%   region_stats  the result of the regionprobs function for the area to be
%                 scanned
%   params        the parameters struct
% results:
%   objects       a struct with the object data

  error( nargchk( 3, 3, nargin ) );
  
%   colors = [ 'g' 'b' 'c' 'm' 'y' 'r' ];
%   color_idx = 1;
  
  objects = struct( 'p', {} );
  
  EMPTY_POINT = struct( 'x', {}, 'o', {}, 'w', {}, 'h', {}, 'b', {} );

  % shrink areas to 8-connected lines
   bw_thin=ridgenew(pic,region_stats.Image);
%   figure; imshow( bw_thin, [] );


  % copy image for further analysis
  bw_feat = zeros( size(bw_thin) + 2 );
  bw_feat(2:end-1,2:end-1) = bw_thin;

  % count surrounding pixels for feature detection
  kernel = [ 1 1 1 ; 1 0 1 ; 1 1 1 ];
  bw_feat = bw_feat .* conv2( double(bw_feat), kernel, 'same' );
  
%   figure; imshow( bw_feat, [] );
  
  [ ey, ex ] = find( bw_feat == 1 ); % find endpoints
  [ cy, cx ] = find( bw_feat  > 2 ); % find crossings
   
%   for jkl=1:numel(cx)
%     PlotPoints( [cx(jkl) cy(jkl)] + region_stats.BoundingBox(1:2)-1.5, 'g' );
%   end
  
  if numel(cx) == 0 % no crossings!
    
    if numel(ex) <= 1 % must be a point-like object
      if params.find_beads
        objects = FindPointObjects( region_stats, params );
      end
      return
    elseif numel(ex) ~= 2 % this case is theoretically not possible -.-
      error( 'MPICBG:FOTS:UnexpectedBehavior', 'An object without crossings should have exactly two end points' );
    end
    % add whole chain to object array
    chains{1} = getPointChain( ex(1), ey(1) );
    
  else % there are crossings
    
    chains = cell( 1, numel(ex) );
    
    % find clusters starting at end points
    % each end point has his own chain - there are no endpoints connected
    % directly!
    for k = 1 : numel(ex)
      chains{k} = getPointChain( ex(k), ey(k) );
    end
    
    % find clusters of crossings
    c = [ cx cy ];

    c_idx = getClusters( c, 1.5, 'max' );
    
    for cur_idx = unique(c_idx) % run through all clusters
      % find crossings in this cluster
      f = find( c_idx == cur_idx );
      center = mean( c(f,:), 1 ); % center of cluster
      
%       PlotPoints( center + region_stats.BoundingBox(1:2)-1.5, 'g' );
      
      % find attached chains for all points in cluster
      a = []; % attached points leading to chains
      % 1: x - coordinate
      % 2: y - coordinate
      % 3: index of chain
      % 4: orientation of chain towards the center
      for i = f
        [ dy, dx ] = find( bw_feat(cy(i)-1:cy(i)+1,cx(i)-1:cx(i)+1) < 3 & ...
                           bw_feat(cy(i)-1:cy(i)+1,cx(i)-1:cx(i)+1) > 0 );
        a = [ a ; cx(i) + dx - 2 ...        % x - coordinate
                  cy(i) + dy - 2 ...        % y - coordinate
                  zeros( numel(dx), 1 ) ];  % reserved space
      end
      a = unique( a, 'rows' );
      
%       for jkl=1:size(a,2)
%         PlotPoints( a(jkl,1:2) + region_stats.BoundingBox(1:2)-1.5, 'g' );
%       end
      
      % check if one of the attached points is the end of already found
      % chain or otherwise find the whole chain
      for a_i = 1 : size( a, 1 )
        % check, if point is in chains
        for k = 1 : numel( chains )
          if ~isempty( chains{k} ) && all( chains{k}(end,1:2) == a(a_i,1:2) )
            [ c_id, a(a_i,3) ] = deal( k );
            break;
          end
        end
        
        % or otherwise locate new chain
        if a(a_i,3) == 0 % not assigned to any existing chain
          % We have to remove the points of the cluster to find the right path
          % for the chain. This is done using a suitable kernel for the
          % getPointChain()-function.
          ker = bw_feat;
          for c_i = f % remove points of center cluster
            ker(cy(c_i),cx(c_i)) = 0;
          end
          ker = ker(a(a_i,2)-1:a(a_i,2)+1,a(a_i,1)-1:a(a_i,1)+1) > 0; % grab kernel
          ker(2,2) = 0; % remove central point
          chains{end+1} = getPointChain( a(a_i,1), a(a_i,2), ker ); % find chain
%           chains{end} = chains{end}(end:-1:1,:); % invert chain, such that our point is always in the last position
          [ c_id, a(a_i,3) ] = deal( numel(chains) ); % store index
        end
        
        % calculate orientation for each chain
        len = min( size( chains{c_id}, 1 ), round( 2 * params.object_width ) ) - 1;
        a(a_i,4) = atan2( chains{c_id}(end-len,2) - center(2), ...
                          chains{c_id}(end-len,1) - center(1) );
      end
      
%       PlotOrientations( a( :, [1 2 4 ] ) );
      
      % we have now all incoming chains and have to connect them - we do
      % this by looking at the differences in orientation

      % build correlation matrix
      angle_max = pi/2;
      angles = mod( repmat( a(:,4)', size(a,1), 1 ) - repmat( a(:,4), 1, size(a,1) ) + pi, 2*pi );

      while true % run until there are no correlated chunks anymore
        [ a_min, x ] = min( angles );
        [ a_min, y ] = min( a_min );
        if a_min >= angle_max % no correlated chunks anymore => break
          break;
        end
        y = y(1);
        x = x(y);
        i1 = round( a(x,3) );
        i2 = round( a(y,3) );
        % connect chain x and y
        chains{i1} = [ chains{i1} ; chains{i2}(end:-1:1,:) ];
        chains{i2} = []; % set other chain to empty
        
        % set entries to Inf, such that these chains are not connected anymore
        angles( [ x y ], : ) = Inf;
        angles( :, [ x y ] ) = Inf;
      end
      
    end % of run through all clusters
  end % of choice, if there are crossings in object

  function points = getPointChain( x, y, firstkernel )
    % uses 'kernel' and 'bw_feat' from parent function
    
    if nargin < 3
      ker = kernel;
    else
      ker = firstkernel;
    end
    
    % find first point
    points = [ x y ];
    [ dy, dx ] = find( bw_feat(y-1:y+1,x-1:x+1) .* ker > 0, 1 );
    x = x + dx - 2;
    y = y + dy - 2;
    
    % find all conneted middle points
    while bw_feat(y,x) == 2 % run while it is a middle point
      points(end+1,1:2) = [ x y ]; %#ok<AGROW>
      ker = kernel;
      ker( 4 - dy, 4 - dx ) = 0; % dont find the last point again!
      [ dy, dx ] = find( bw_feat(y-1:y+1,x-1:x+1) .* ker > 0, 1 );
      x = x + dx - 2;
      y = y + dy - 2;
    end
  end

  % cleanup: delete empty chains
  i = 1;
  while i <= numel(chains)
    if isempty( chains{i} )
      chains(i) = [];
    else
      i = i + 1;
    end
  end

  % store chain information in objects struct
  objects = repmat( struct( 'p', EMPTY_POINT ), 1, numel(chains) ); % init & preallocate
  for i = 1:numel(chains) % run through chains
    
    if size( chains{i}, 1 ) > 1 % elongated object
      if size( chains{i}, 1 ) < params.short_object_threshold
        % convert to small MT if its a short chain
        chains{i} = [ chains{i}(1,:) ; chains{i}(end,:) ]; %#ok<AGROW>
      else
        % otherwise average the whole chain
        chains{i} = AverageChain( chains{i}, round( params.object_width ) ); %#ok<AGROW>
      end
      
      % calculate orientation
      o = atan2( chains{i}(2:end,2) - chains{i}(1:end-1,2), ...
                 chains{i}(2:end,1) - chains{i}(1:end-1,1) );
      for k = 1:size( chains{i}, 1 ) % run through all points of chain
        % add offset of region and remove 1 because of extended bw_thin array
        objects(i).p(k).x = chains{i}(k,1:2) + region_stats.BoundingBox(1:2) - 1.5;
        % add orientation information to each point
        if k == 1
          objects(i).p(k).o = o(1);
        elseif k == size( chains{i}, 1 )
          objects(i).p(k).o = o(end);
        else
          objects(i).p(k).o = mean( o(k-1:k) );
        end
      end
    else % point-like object
      objects(i).p(1).x = chains{i}(1,1:2) + region_stats.BoundingBox(1:2) - 1.5;
    end % of choice of object type
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IMAGE FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function chain = AverageChain( chain, a, closed )
%AVERAGECHAIN takes a whole list of points and averages them with a running mean
%filter. The length of the filter is 'a'. The function can handle both closed
%and open chains.
%
% arguments:
%   chain   a n-by-2 array of points or a struct containing the array as field x
%   a       the length of the filter in one direction (the total length is 2a+1)
%   closed  determines if this is a closed chain. The defaul value is 'false'
% results:
%   chain   an array of the same size as the input

  if nargin < 3
    closed = false;
  end
  
  if isstruct( chain )
    
    % setup expanded list
    x = tranpose( reshape( [ chain.x ], 2, [] ) );
%     x = getfields( chain, {}, 'x', {1:2} );
    if closed
      x = [ x(end-a+1:end,1:2) ; x ; x(1:a,1:2) ];
    else
      x = [ repmat( x(1,1:2), a, 1 ) ; x ; repmat( x(end,1:2), a, 1 ) ];
    end
    x = filter( ones(1,a)/a, 1, x );

    % average using a mean filter
    o = [ chain.o ];
    if closed
      o = [ o(end-a+1:end) o o(1:a) ];
    else
      o = [ repmat( o(1), 1, a ) o repmat( o(end), 1, a ) ];
    end
    o = filter( ones(1,a)/a, 1, unwrap(o) );
    for i = 1:numel(chain)
      chain(i).x = x( a+i, 1:2 );
      chain(i).o = o( a+i );
    end
    
  else % chain is no structure, but ordinary array
    
    % setup expanded list
    x = chain( :, 1:2 );
    if closed
      x = [ x(end-a+1:end,1:2) ; x ; x(1:a,1:2) ];
    else
    x = [ repmat( x(1,1:2), a, 1 ) ; x ; repmat( x(end,1:2), a, 1 ) ];
    end
    x = filter( ones(1,a)/a, 1, x );

    % average using a mean filter
    if size( chain, 2 ) > 2
      o = chain( :, 3 );
      if closed
        o = [ o(end-a+1:end) ; o ; o(1:a) ];
      else
        o = [ repmat( o(1), a, 1 ) ; o ; repmat( o(end), a, 1 ) ];
      end
      o = filter( ones(1,a)/a, 1, unwrap(o) );
      chain = [ x( a+1:end-a, 1:2 ) o( a+1:end-a ) ];
    else
      chain = x( a+1:end-a, 1:2 );
    end
    
  end
end

% function [ b, idx ] = CombineClosePoints( a, dist, strict )
% %COMBINECLOSEPOINTS scans through an array of points and averages points which
% %are close to each other.
% % arguments:
% %   a       the list of points - n by 2 array
% %   dist    the minium distance two points are allowed to be close to each other
% %   strict  determines if splitting is allowed (it is, if value is set to false)
% % result:
% %   b       a new list of points fullfilling the distance condition
% %   idx     an array with same length as 'a' containing same numbers for combinded
% %           and different numbers for points not belonging to same cluster
% 
%   if nargin < 3
%     strict = false;
%   end
%   
%   pos = getfields( a, {}, 'x', {1:2} );
%   if strict
%     idx = getClusters( pos, dist, 2 ); % no splitting
%   else
%     idx = getClusters( pos, dist, 2, dist^2 ); % splitting for large areas
%   end    
% 
%   % preallocate array
%   b = struct( 'x', {}, 'o', {}, 'w', {}, 'h', {}, 'p', {} );
%   k = numel(unique(idx)); % go upside down to preallocate array
%   for i = unique(idx) % run through clusters
%     f = find( idx == i );
%     b(k).x = mean( pos(f,1:2), 1 ); % average position
%     if isfield( a, 'o' )
%       b(k).o = mean( unwrap( [ a(f).o ] ) ); % average orientation
%     end
%     k = k - 1;
%   end
% end

function bw=ridgenew(picture,bw)
pic=(picture-min(picture(bw))+1).*bw;
pic = pic.*bwdist(bw==0);

y=size(pic,1);
x=size(pic,2);
b=zeros(y,x,8);
bw=zeros(y,x);
    
%find peaks

% 1 if greater than neighbor, 0 if not greater, -1 if neighbour is inf
b(2:y  ,1:x-1,1)=double((pic(2:y  ,1:x-1)>pic(1:y-1,2:x  ))&(pic(1:y-1,2:x  )>0)); %northeast m0
b(2:y  ,1:x  ,2)=double((pic(2:y  ,1:x  )>pic(1:y-1,1:x  ))&(pic(1:y-1,1:x  )>0)); %north m1
b(2:y  ,2:x  ,3)=double((pic(2:y  ,2:x  )>pic(1:y-1,1:x-1))&(pic(1:y-1,1:x-1)>0)); %northwest m2
b(1:y  ,2:x  ,4)=double((pic(1:y  ,2:x  )>pic(1:y  ,1:x-1))&(pic(1:y  ,1:x-1)>0)); %west m3
b(1:y-1,2:x  ,5)=double((pic(1:y-1,2:x  )>pic(2:y  ,1:x-1))&(pic(2:y  ,1:x-1)>0)); %southwest m4
b(1:y-1,1:x  ,6)=double((pic(1:y-1,1:x  )>pic(2:y  ,1:x  ))&(pic(2:y  ,1:x  )>0)); %south m5
b(1:y-1,1:x-1,7)=double((pic(1:y-1,1:x-1)>pic(2:y  ,2:x  ))&(pic(2:y  ,2:x  )>0)); %southeast m6
b(1:y  ,1:x-1,8)=double((pic(1:y  ,1:x-1)>pic(1:y  ,2:x  ))&(pic(1:y  ,2:x  )>0)); %east m7

%find diagnoal peaks
bw(b(:,:,1)==1 & b(:,:,3)==1 & b(:,:,5)==1 & b(:,:,7)==1  & ~( (b(:,:,2)==0 | b(:,:,6)==0) & (b(:,:,4)==0 | b(:,:,8)==0 )) )=1;
%find vertical&horizontal peaks
bw(b(:,:,2)==1 & b(:,:,4)==1 & b(:,:,6)==1 & b(:,:,8)==1  & ~( (b(:,:,1)==0 | b(:,:,5)==0) & (b(:,:,3)==0 | b(:,:,7)==0 )) )=1;

pic_old=zeros(y,x);
while ~isequal(pic,pic_old)
    %find saddle points
    g=ones(y,x,8);
    % 1 if greater than neighbor, 0 if not greater, -1 if neighbour is inf
    g(2:y  ,1:x-1,1)=double(pic(2:y  ,1:x-1)>pic(1:y-1,2:x  ))-1*isinf(pic(1:y-1,2:x  )); %northeast m0
    g(2:y  ,1:x  ,2)=double(pic(2:y  ,1:x  )>pic(1:y-1,1:x  ))-1*isinf(pic(1:y-1,1:x  )); %north m1
    g(2:y  ,2:x  ,3)=double(pic(2:y  ,2:x  )>pic(1:y-1,1:x-1))-1*isinf(pic(1:y-1,1:x-1)); %northwest m2
    g(1:y  ,2:x  ,4)=double(pic(1:y  ,2:x  )>pic(1:y  ,1:x-1))-1*isinf(pic(1:y  ,1:x-1)); %west m3
    g(1:y-1,2:x  ,5)=double(pic(1:y-1,2:x  )>pic(2:y  ,1:x-1))-1*isinf(pic(2:y  ,1:x-1)); %southwest m4
    g(1:y-1,1:x  ,6)=double(pic(1:y-1,1:x  )>pic(2:y  ,1:x  ))-1*isinf(pic(2:y  ,1:x  )); %south m5
    g(1:y-1,1:x-1,7)=double(pic(1:y-1,1:x-1)>pic(2:y  ,2:x  ))-1*isinf(pic(2:y  ,2:x  )); %southeast m6
    g(1:y  ,1:x-1,8)=double(pic(1:y  ,1:x-1)>pic(1:y  ,2:x  ))-1*isinf(pic(1:y  ,2:x  )); %east m7
    
    pic_old=pic;

    %find saddles
    bw(g(:,:,1)==-1 & g(:,:,8)==1 & ( g(:,:,7)<1 | g(:,:,6)<1 | g(:,:,5)<1 ) & ( g(:,:,2)==1 | g(:,:,4)==1))=1;
    bw(g(:,:,1)==-1 & g(:,:,2)==1 & ( g(:,:,3)<1 | g(:,:,4)<1 | g(:,:,5)<1 ) & ( g(:,:,8)==1 | g(:,:,6)==1))=1;        
    
    bw(g(:,:,2)==-1 & g(:,:,4)==1 & g(:,:,8)==1 & ( g(:,:,5)<1 | g(:,:,6)<1 | g(:,:,7)<1 ))=1;
    
    bw(g(:,:,3)==-1 & g(:,:,2)==1 & ( g(:,:,1)<1 | g(:,:,8)<1 | g(:,:,7)<1 ) & ( g(:,:,4)==1 | g(:,:,6)==1))=1;
    bw(g(:,:,3)==-1 & g(:,:,4)==1 & ( g(:,:,5)<1 | g(:,:,6)<1 | g(:,:,7)<1 ) & ( g(:,:,2)==1 | g(:,:,8)==1))=1;        

    bw(g(:,:,4)==-1 & g(:,:,6)==1 & g(:,:,2)==1 & ( g(:,:,7)<1 | g(:,:,8)<1 | g(:,:,7)<1 ))=1;
    
    bw(g(:,:,5)==-1 & g(:,:,4)==1 & ( g(:,:,3)<1 | g(:,:,2)<1 | g(:,:,1)<1 ) & ( g(:,:,6)==1 | g(:,:,8)==1))=1;
    bw(g(:,:,5)==-1 & g(:,:,6)==1 & ( g(:,:,7)<1 | g(:,:,8)<1 | g(:,:,1)<1 ) & ( g(:,:,4)==1 | g(:,:,2)==1))=1;        

    bw(g(:,:,6)==-1 & g(:,:,8)==1 & g(:,:,4)==1 & ( g(:,:,1)<1 | g(:,:,2)<1 | g(:,:,3)<1 ))=1;
    
    bw(g(:,:,7)==-1 & g(:,:,6)==1 & ( g(:,:,5)<1 | g(:,:,4)<1 | g(:,:,3)<1 ) & ( g(:,:,8)==1 | g(:,:,2)==1))=1;
    bw(g(:,:,7)==-1 & g(:,:,8)==1 & ( g(:,:,1)<1 | g(:,:,2)<1 | g(:,:,3)<1 ) & ( g(:,:,6)==1 | g(:,:,4)==1))=1;   
    
    bw(g(:,:,8)==-1 & g(:,:,2)==1 & g(:,:,6)==1 & ( g(:,:,3)<1 | g(:,:,4)<1 | g(:,:,5)<1 ))=1;
    
    pic(bw==1)=Inf;
end

pic_old=zeros(y,x);
while ~isequal(pic,pic_old)
    g=zeros(y,x,8);
    g(2:y  ,1:x-1,1)=double((pic(2:y  ,1:x-1)>pic(1:y-1,2:x  ))&(pic(1:y-1,2:x  )>0))-1*isinf(pic(1:y-1,2:x  )); %northeast m0
    g(2:y  ,1:x  ,2)=double((pic(2:y  ,1:x  )>pic(1:y-1,1:x  ))&(pic(1:y-1,1:x  )>0))-1*isinf(pic(1:y-1,1:x  )); %north m1
    g(2:y  ,2:x  ,3)=double((pic(2:y  ,2:x  )>pic(1:y-1,1:x-1))&(pic(1:y-1,1:x-1)>0))-1*isinf(pic(1:y-1,1:x-1)); %northwest m2
    g(1:y  ,2:x  ,4)=double((pic(1:y  ,2:x  )>pic(1:y  ,1:x-1))&(pic(1:y  ,1:x-1)>0))-1*isinf(pic(1:y  ,1:x-1)); %west m3
    g(1:y-1,2:x  ,5)=double((pic(1:y-1,2:x  )>pic(2:y  ,1:x-1))&(pic(2:y  ,1:x-1)>0))-1*isinf(pic(2:y  ,1:x-1)); %southwest m4
    g(1:y-1,1:x  ,6)=double((pic(1:y-1,1:x  )>pic(2:y  ,1:x  ))&(pic(2:y  ,1:x  )>0))-1*isinf(pic(2:y  ,1:x  )); %south m5
    g(1:y-1,1:x-1,7)=double((pic(1:y-1,1:x-1)>pic(2:y  ,2:x  ))&(pic(2:y  ,2:x  )>0))-1*isinf(pic(2:y  ,2:x  )); %southeast m6
    g(1:y  ,1:x-1,8)=double((pic(1:y  ,1:x-1)>pic(1:y  ,2:x  ))&(pic(1:y  ,2:x  )>0))-1*isinf(pic(1:y  ,2:x  )); %east m7

    pic_old=pic;

    bw(sum(g==1,3)>5 & min(g,[],3)==-1 )=1;    
    pic(bw==1)=Inf;
end
g=zeros(y,x,8);
g(2:y  ,1:x-1,1)=bw(1:y-1,2:x  );
g(2:y  ,1:x  ,2)=bw(1:y-1,1:x  ); %north m1
g(2:y  ,2:x  ,3)=bw(1:y-1,1:x-1); %northwest m2
g(1:y  ,2:x  ,4)=bw(1:y  ,1:x-1); %west m3
g(1:y-1,2:x  ,5)=bw(2:y  ,1:x-1); %southwest m4
g(1:y-1,1:x  ,6)=bw(2:y  ,1:x  ); %south m5
g(1:y-1,1:x-1,7)=bw(2:y  ,2:x  ); %southeast m6
g(1:y  ,1:x-1,8)=bw(1:y  ,2:x  ); %east m7
bw(g(:,:,1) & g(:,:,2) & g(:,:,3) & ~(g(:,:,5) | g(:,:,6) | g(:,:,7)) )=0;
bw(g(:,:,3) & g(:,:,4) & g(:,:,5) & ~(g(:,:,7) | g(:,:,8) | g(:,:,1)) )=0;
bw(g(:,:,5) & g(:,:,6) & g(:,:,7) & ~(g(:,:,1) | g(:,:,2) | g(:,:,3)) )=0;
bw(g(:,:,7) & g(:,:,8) & g(:,:,1) & ~(g(:,:,3) | g(:,:,4) | g(:,:,5)) )=0;
bw(g(:,:,2) & g(:,:,4) & sum(g,3)==2)=0;
bw(g(:,:,4) & g(:,:,6) & sum(g,3)==2)=0;
bw(g(:,:,6) & g(:,:,8) & sum(g,3)==2)=0;
bw(g(:,:,8) & g(:,:,2) & sum(g,3)==2)=0;
bw(g(:,:,2) & g(:,:,7) & g(:,:,8) & sum(g,3)==3 & ~b(:,:,8))=0;
bw(g(:,:,2) & g(:,:,5) & g(:,:,4) & sum(g,3)==3 & ~b(:,:,4))=0;
bw(g(:,:,4) & g(:,:,1) & g(:,:,2) & sum(g,3)==3 & ~b(:,:,2))=0;
bw(g(:,:,4) & g(:,:,7) & g(:,:,6) & sum(g,3)==3 & ~b(:,:,6))=0;
bw(g(:,:,6) & g(:,:,1) & g(:,:,8) & sum(g,3)==3 & ~b(:,:,8))=0;
bw(g(:,:,6) & g(:,:,3) & g(:,:,4) & sum(g,3)==3 & ~b(:,:,4))=0;
bw(g(:,:,8) & g(:,:,3) & g(:,:,2) & sum(g,3)==3 & ~b(:,:,2))=0;
bw(g(:,:,8) & g(:,:,5) & g(:,:,6) & sum(g,3)==3 & ~b(:,:,6))=0;
end