close all
clear
clc
%%
M=SkinModel;
M.Read('fc_binary.stl');
%%
M.addprop('SF1');
M.SF1.V=M.V;
M.SF1.V(:,4)=linspace(1,size(M.SF1.V,1),size(M.SF1.V,1));
M.SF1.VN=M.VN;
M.SF1.VN(:,4)=linspace(1,size(M.SF1.V,1),size(M.SF1.V,1));
M.SF1.T=M.T;
M.SF1.N=M.N;
%%
M.MD(3,29,10);
%%
for i=1:30
    M.MD(3,i,10);
end



%%
M=SkinModel;

M.V=[0,0,0
          1,0,0
          0,1,0
          1,1,0];
M.VN=[0,0,1];
M.VN=repmat(M.VN,4,1);
M.N=[0,0,1
          0,0,1];
M.T=[1,2,3
          2,4,3];
 
M.addprop('SF1');
M.SF1.V=M.V;
M.SF1.V(:,4)=linspace(1,size(M.SF1.V,1),size(M.SF1.V,1));
M.SF1.VN=M.VN;
M.SF1.VN(:,4)=linspace(1,size(M.SF1.V,1),size(M.SF1.V,1));
M.SF1.T=M.T;
M.SF1.N=M.N;

%%
M.MD(1,4,10);