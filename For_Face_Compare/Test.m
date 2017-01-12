close all
clear all
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
M.MD(1,29,1);
%%
D=zeros(513,1);
for i=1:40
    M.MD(1,i,1);
    view(50,30);
    axis on;
    shading interp;
    %-------------------------------------------------
    if i==2
        D=D+0.5*M.SF1.D;
    end
    if i==3
        D=D+0.2*M.SF1.D;
    end
    if i==4
        D=D+0.2*M.SF1.D;
    end
    if i==7
        D=D+0.2*M.SF1.D;
    end
    if i==8
        D=D+0.2*M.SF1.D;
    end
    if i==12
        D=D+0.4*M.SF1.D;
    end
    %-------------------------------------------------
end
M.SF1.V(:,3)=M.SF1.V(:,3)+10*D;
trisurf(M.SF1.T,M.SF1.V(:,1),M.SF1.V(:,2),M.SF1.V(:,3),D);