%% BundleAdjustment.m

close all;
clc;
clear;


%% Input Path
% % % m      
 szCal = 'DunHuansparce\cal63.txt';
 szCam = 'DunHuansparce\Cam63.txt';
 szFea = 'DunHuansparce\Feature63sssparce.txt';
 szXYZ = 'DunHuansparce\outpoints.txt';


%%%%%%%%%%%%%%%%village
% szCal = 'villagesparse\cal90.txt';
% szCam = 'villagesparse\Cam90.txt';
% szFea = 'villagesparse\Feature900ssssparse.txt';
% szXYZ = 'villagesparse\outpoints.txt';

% %  
%   szCal = 'Malagasparce\cal170.txt';
%   szCam = 'Malagasparce\Cam170.txt';
%   szFea = 'Malagasparce\FeatureSparce170.txt';%1Feature_tst.txt2match_FINE.txt
%   szXYZ = 'Malagasparce\outpoints170.txt'; %2match_outPnts.txt   
%  szFea = 'Malagasparce\FeatureSparce1.txt';%1Feature_tst.txt2match_FINE.txt
%  szXYZ = 'Malagasparce\Outpoints.txt'; %2match_outPnts.txt   

% szCal = 'College\College\cal468.txt';
% szCam = 'College\College\Cam468.txt';
% szFea = 'College\College\Feature468.txt';%1Feature_tst.txt2match_FINE.txt
% szXYZ = 'College\College\College468.txt'; 

% szCal = 'college468\cal468.txt';
% szCam = 'college468\Cam468new.txt';
% % szFea = 'college468\collegeFeatureSparce.txt';%1Feature_tst.txt2match_FINE.txt
% % szXYZ = 'college468\collegeOutpoints.txt'; 
% szFea = 'college468\FeatureSsparse.txt';%1Feature_tst.txt2match_FINE.txt
% szXYZ = 'college468\outpoint-s.txt'; 

LSMode =4;     %1--GN, 2--LM  3--EBFGS 4-BFGS

xVector.u = []; xVector.PID = []; xVector.FID = [];
PVector.Pose = []; PVector.Feature = []; PVector.ID = []; PVector.Info = sparse([]);
PVector.Num = [];

%%%%%%%%%%%
%xVector里面放的是  Feature   真值
%pVector里面放的是  R t K XYZ 通过pVector即可 得到观测值
%%%%%%%%%
%% Load Pose
K = textread(szCal);
PoseInit = load(szCam);
[a, b] = size(PoseInit);
ImageNum=a;
for i=1:ImageNum;
    PVector.Pose(6*(i-1)+1:6*i,1) = PoseInit(i,1:6)';  %%%所有的pose放在PVector的Pose中
end;

%% Load Features
clc;
fidin=fopen(szFea);                               % 打开test2.txt文件  
ptno = 1;
maxObj = -1;
while ~feof(fidin)
    nframes = fscanf( fidin, '%d', [1,1] );
    
    for j=1:nframes;
        tmp = fscanf( fidin, '%d %f %f', [3, 1]);
        xVector.PID = [xVector.PID; tmp(1)+1 ];
        xVector.FID = [xVector.FID; ptno];        
        xVector.u = [ xVector.u; tmp(2:3, 1) ];
    end;
    
    if maxObj < nframes;
       maxObj = nframes;
    end;
    
    PVector.Num = [ PVector.Num, nframes ];
    ptno = ptno+1;
end 
fclose(fidin); 
% ReadTime = toc;
% fprintf('Read Features %d\n\n', ReadTime);


%% Initial Features
clc;
XYZinit = load( szXYZ );


% Feature = zeros(ptno,maxObj*3+8);
%[PVector,Feature] = FuncInitFea(PVector,Feature,xVector,K);
[PVector] = FuncInitFeaXYZ(PVector,XYZinit );
%InitTime = toc;
% fprintf('Initize Features %d\n\n', InitTime );

%% Choose Variavle to Fix
shiftX = abs(PoseInit(2,4)-PoseInit(1,4));
shiftY = abs(PoseInit(2,5)-PoseInit(1,5));
shiftZ = abs(PoseInit(2,6)-PoseInit(1,6));
Shift = [shiftX, shiftY, shiftZ ];
[MaxShift, idx] = max(Shift);
clear PoseInit;

if idx == 1;
    FixVa = 1;
end; 
if idx == 2;
    FixVa = 2;
end;
if idx == 3;
    FixVa = 3;
end;

% tic;
%% Least Squares
if LSMode==1;
   [PVector,Reason,Info] = FuncLeastSquares(xVector,PVector,K,FixVa);
   
elseif LSMode==2 ;
   [PVector,Reason,Info] = FuncLeastSquaresLMSBA(xVector,PVector,K,FixVa);
elseif LSMode==3
   %[PVector,Reason,Info]=FuncLeastSquaresSBFGS(xVector,PVector,K,FixVa);
  [PVector,Reason,Info]= FuncLeastSquaresBFGS(xVector,PVector,K,FixVa);
else
     [PVector,Reason,Info]=FuncLeastSquaresHybird(xVector,PVector,K,FixVa);
end;    

%% Levenberg-Marquardt Iteration SBA
      %[PVector,Reason,Info] = FuncLeastSquaresLMSBA(xVector,PVector,K,FixVa);
     
fprintf('Reason is %d\n', Reason);
    
% PVector.ID = Feature(:,1:4);
% PVector.Info = Info;


