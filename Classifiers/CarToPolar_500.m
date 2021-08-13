% Yanan Niu
% Impact and Implications of Mixed Plaque class in Automated Characterization of Complex Atherosclerotic Lesions
% version 26/07/2021

% Convert OCT from Cartesian coordinates into Polar coordinates
%   input -----------------------------------------------------------------
%      Name                Value
%      'OCT_cart'       OCT in Cartesian coordinates, 500*500*n 

%   Output ----------------------------------------------------------------
%      Name                Value
%      'OCT_pol'        OCT in Polar coordinates, 500*500*n

function [OCT_pol]=CarToPolar_500(OCT_car)

t = repmat(1:500,500,1)-0.5; %degree
r = t'; %redius

% Now, x & y in corrdinate centered in (250，250）
[x,y] = pol2cart(t*(2*pi)/500,r*250/500); %radius=r*
x_pol = round(x+250);
y_pol = round(y+250);

% x_pol,y_pol used as index, so 0 should all be replaced by 1 (min index)
x_pol(x_pol==0)=1;
y_pol(y_pol==0)=1;

OCT_pol=zeros(500,500,size(OCT_car,size(OCT_car,3)));
x_pol = repmat(x_pol,1,1,size(OCT_car,3));
y_pol = repmat(y_pol,1,1,size(OCT_car,3));
for d = 1:size(OCT_car,3)
    for j=1:500  %row
        for i = 1:500 %coloum
            OCT_pol(i,j,d) = OCT_car(x_pol(i,j,d),y_pol(i,j,d));
        end
    end
end
end
