% Pan + (MS + HS)

clear
addpath('function')

load('Data\Botswana.mat')
load('Noise\N_Botswana.mat')
beta1=1.3e-4;                               % regularization parameter
beta2=1.3e-4;                               % regularization parameter
ps=14:36;
% load('Data\IndianPines.mat')
% load('Noise\N_IndianPines.mat')
% beta1=1.2e-4;                               % regularization parameter
% beta2=1.2e-4;
% ps=10:30;
% load('Data\DCMall.mat')
% load('Noise\N_DCMall.mat')
% beta1=4e-4;                                 % regularization parameter
% beta2=4e-4;
% ps=24:53;
% load('Data\Moffett.mat')
% load('Noise\N_Moffett.mat')
% beta1=8e-4;                                 % regularization parameter
% beta2=8e-4;
% ps=14:36;
% load('Data\KennedySpaceCenter.mat')
% load('Noise\N_KennedySpaceCenter.mat')
% beta1=8e-4;                                 % regularization parameter
% beta2=8e-4;
% ps=14:36;

% paramaters
ni  =200;                                   % number of iterations
snrh=30;                                    % HS SNR (dB)
snrm=30;                                    % MS SNR (dB)
snrp=40;                                    % pan SNR (dB)
mu  =.02;                                   % penalty parameter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spectral responses
Nm=7;        % number of bands
R=multibands_Landsat(w);
c=R(6,:);
c=c/sum(c);
R(6,:)=[];   %%%%%%%%%%%
R=R./(sum(R,2)*ones(1,Ns));
RE=R*E;
cE=c*E;

%% MTFs (blur kernels)
rm =2;                                   % MS spatial downsampling factor
Npm=Np/rm^2;                             % MS number of pixels
Km =fspecial('gaussian',[3,3],.8);       % MS spatial filter kernel
rh =4;                                   % HS spatial downsampling factor
Kh =conv2(Km,Km);                        % HS spatial filter kernel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% synthesize images
[~,p2,~]         =createPan(I2,nr,nc,c,nop,snrp);               % Pan
[~,M2,nrm,ncm,Sm]=createMS (I3,rm,Km,nr,nc,Ns,R,Nm,Nom,snrm);   % MS
[~,H2,nrh,nch,Sh]=createHS (I3,rh,Kh,nr,nc,Ns,Noh,snrh);        % HS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% fusion
% MS+HS
[Y3,~,t1]=HySure(H2,M2,E,RE,Km,1,beta1,mu,ni,rh/rm,nrm,ncm,nrh,nch,Npm,Ns,Ne);
%[Y3,~,t1]=RFUSE_TV(H2,M2,E,RE,Km,beta1,mu,ni,rh/rm,nrm,ncm,nrh,nch,Npm,Ns,Ne);
Y2=reshape(Y3,[Npm,Ns])';

% Pan+(MS+HS)
[X3,~,t2]=HySure(Y2,p2,E,cE,Km,1,beta2,mu,ni,rm,nr,nc,nrm,ncm,Np,Ns,Ne);
%[X3,~,t2]=RFUSE_TV(Y2,p2,E,cE,Km,beta2,mu,ni,rm,nr,nc,nrm,ncm,Np,Ns,Ne);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% results
[ergas,sam,q2n]=qual_assess(I3(:,:,ps),X3(:,:,ps),rh,length(ps),Np,32);
fprintf('\n spectrum of pan\n ERGAS = %2.3f\n SAM   = %2.3f\n Q2n   = %2.3f',...
    ergas,sam,q2n)

[ergas,sam,q2n]=qual_assess(I3,X3,rh,Ns,Np,32);
fprintf('\n entire spectrum\n ERGAS = %2.3f\n SAM   = %2.3f\n Q2n   = %2.3f\n time  = %2.3f\n'...
    ,ergas,sam,q2n,t1+t2)

nrmse=zeros(Np,1);
X2p=reshape(X3(:,:,ps),[Np,length(ps)])';
I2p=reshape(I3(:,:,ps),[Np,length(ps)])';
for ii=1:Np
    nrmse(ii)=norm(X2p(:,ii)-I2p(:,ii))/norm(I2p(:,ii))*100;
end
figure, plot(sort(nrmse)), title('spectrum of pan')
xlabel('pixel number'), ylabel('per-pixel NRMSE (%)')

nrmse=zeros(Np,1);
X2=reshape(X3,[Np,Ns])';
for ii=1:Np
    nrmse(ii)=norm(X2(:,ii)-I2(:,ii))/norm(I2(:,ii))*100;
end
figure, plot(sort(nrmse)), title('entire spectrum')
xlabel('pixel number'), ylabel('per-pixel NRMSE (%)')
