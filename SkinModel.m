classdef SkinModel < handle & dynamicprops
%--------------------------------------------------------------------------
% Generate Skin Model from original binary STL file.
%   Following the sequance of the methods:
%   1. Read
%   2. Seg
%   3. Sim deviation
%   4. Comb
%   5. Export
%--------------------------------------------------------------------------
% Read before using:
%   1. If it's the first time simulate for a model, use the tyical process.
%   2. Segmentation works well only for:
%       1> Part with sharp and acute face connection
%       2> Size of each feature shold be similar
%   3. Once segmentation are done and the result is satisfying, save the
%      instance of the model, thus the numbering of surfaces after seg are
%      fixed, and don't need to seg it again the next time.
%   4. Specify manufacturing deviations by methods:
%       1> TR--translation
%       2> RO--rotation
%       3> MD--generate mode and scaled
%   5. All deviations are considered as displacement boundary conditions,
%      and solving by FEA & Penalty Function Approach.
%   6. 'ResetD'--To generate a new skin model, use this method to set
%      manufacturing deviation to zero. Not necessary to reload model.
%--------------------------------------------------------------------------

    
    properties
        % These properties are for the original model.
        V;
        T;
        N;
        VN;
        % Other segmentation properties are saved as dynamic properties.
        N_Surf;
        % Basic Properties for FEA combination
        ELM; % Generated during segmentation
        K;
        C;
        D;
        S=1e17;
        % Skin Model parameters
        SM;
    end
    
    methods
        
        % Read original STL file.
        function Read( Obj, filename )
            
            % Open the file, assumes STL Binary format.
            fid=fopen( filename, 'r');
            if fid == -1
                error('File could not be opened, please check name or path!')
            end
            
            % Read file title and number of facets
            ftitle=fread(fid,80,'uchar=>schar');
            num_facet=fread(fid,1,'int32');
            
            % Pre-allocate memory to save running time
            Obj.V=zeros(3*num_facet,3);
            Obj.T=zeros(num_facet,3);
            Obj.N=zeros(num_facet,3);
            col=uint16(0);
            for i=1:num_facet,
                Obj.N(i,1)=fread(fid,1,'float32');
                Obj.N(i,2)=fread(fid,1,'float32');
                Obj.N(i,3)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+1,1)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+1,2)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+1,3)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+2,1)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+2,2)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+2,3)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+3,1)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+3,2)=fread(fid,1,'float32');
                Obj.V(3*(i-1)+3,3)=fread(fid,1,'float32');
                Obj.T(i,1)=3*(i-1)+1;
                Obj.T(i,2)=3*(i-1)+2;
                Obj.T(i,3)=3*(i-1)+3;
                col=fread(fid,1,'uint16');
            end
            fclose(fid);
            
            % Delet the duplicated vertices
            % re-link the number in Obj.T to new Obj.V
            [Obj.V, ~, indexn] =  unique(Obj.V, 'rows');
            Obj.T = indexn(Obj.T);
            
            % Re-calculate the normal of triangles
            e1=Obj.V(Obj.T(:,2),:)-Obj.V(Obj.T(:,1),:);
            e2=Obj.V(Obj.T(:,3),:)-Obj.V(Obj.T(:,2),:);
            Obj.N=cross(e1,e2);
            for i=1:size(Obj.N,1)
                Obj.N(i,:)=Obj.N(i,:)/norm(Obj.N(i,:));
            end
            
            % Calculate normal of vertices
            Obj.V(:,4)=linspace(1,size(Obj.V,1),size(Obj.V,1));
            Obj.T(:,4)=linspace(1,size(Obj.T,1),size(Obj.T,1));
            Obj.N(:,4)=linspace(1,size(Obj.N,1),size(Obj.N,1));
            Obj.VN=zeros(size(Obj.V,1),4);
            for i=1:size(Obj.V,1)
                [r,~]=find(Obj.T(:,1:3)==Obj.V(i,4));
                N_used=Obj.N(r,1:3);
                VN_sum=[sum(N_used(:,1)),sum(N_used(:,2)),sum(N_used(:,3))];
                VN=VN_sum/norm(VN_sum);
                Obj.VN(i,:)=[VN,Obj.V(i,4)];
            end
            Obj.V(:,4)=[];
            Obj.T(:,4)=[];
            Obj.N(:,4)=[];
            Obj.VN(:,4)=[];
        end
        
        % Segment model into 'N_Surf' patches, using first 'N_Mode' modes
        function Seg( Obj, N_Mode, N_Surf )
            
            Obj.N_Surf=N_Surf;
            
            % Calculation of the mesh edge
            EG=zeros(size(Obj.V,1),size(Obj.V,1));
            for i=1:size(Obj.T,1)
                n1=Obj.T(i,1);
                n2=Obj.T(i,2);
                n3=Obj.T(i,3);
                
                if EG(n1,n2)==0
                    EG(n1,n2)=i;
                else
                    EG(n2,n1)=i;
                end
                
                if EG(n2,n3)==0
                    EG(n2,n3)=i;
                else
                    EG(n3,n2)=i;
                end
                
                if EG(n3,n1)==0
                    EG(n3,n1)=i;
                else
                    EG(n1,n3)=i;
                end
            end
            EV=[];
            ET=[];
            for i=1:size(EG,1)-1
                for j=i:size(EG,1)
                    if EG(i,j)~=0
                        EV=[EV;i,j];
                        ET=[ET;EG(i,j),EG(j,i)];
                    end
                end
            end
            
          %% Use EV to generate ELM, reduced the same calculation
            Obj.ELM=EV;
            Obj.ELM=sort(Obj.ELM,2);
            Obj.ELM=unique(Obj.ELM,'rows');
          %%
            % Non-closed surface mesh will have edges on the boundary
            mark=[];
            for i=1:size(ET,1)
                if (ET(i,1)==0)||(ET(i,2)==0)
                    mark=[mark;i];
                end
            end
            EV(mark,:)=[];
            ET(mark,:)=[];
            
            % Calculation of the modes
            n_e=size(ET,1);
            DIF=zeros(n_e,1);
            for i=1:n_e
                DIF(i,1)=(norm(Obj.N(ET(i,1),1:3)-Obj.N(ET(i,2),1:3)))^2;% This is important part, and need to improve !
            end
            if mean(DIF)>0.001
                DIF=DIF/mean(DIF);
            end
            W=zeros(n_e,1);
            for i=1:n_e
                W(i,1)=norm(Obj.V(EV(i,1),:)-Obj.V(EV(i,2),:))*exp(-DIF(i,1));
            end
            n_t=size(Obj.T,1);
            L=sparse(n_t,n_t);
            L2=sparse(n_t,n_t);
            for i=1:n_e
                L(ET(i,1),ET(i,2))=W(i,1);
            end
            L=L+L';
            for i=1:n_t
                L2(i,i)=sum(L(i,:));
            end
            L=L2-L;
            %             opts.issym = 1;
            %             [Veig,~]=eigs(L,NUM+1,'SM',opts);
            [Veig,~]=eigs(L,N_Mode,'SM');
            Veig=fliplr(Veig);
            
            % Clustering
            n=size(Veig,2);
            for i=1:n
                a=min(Veig(:,i));
                b=max(Veig(:,i));
                Veig(:,i)=(Veig(:,i)-a)/(b-a);
            end
            ID=kmeans(Veig,N_Surf);% ID is the surface number for triangles
            
            Obj.V(:,4)=linspace(1,size(Obj.V,1),size(Obj.V,1));
            Obj.T(:,4)=linspace(1,size(Obj.T,1),size(Obj.T,1));
            Obj.N(:,4)=linspace(1,size(Obj.N,1),size(Obj.N,1));
            
            for i=1:N_Surf
                name=['SF',num2str(i)];
                Obj.addprop(name);
                Obj.(name).F=find(ID==i);
                Obj.(name).T=Obj.T(Obj.(name).F,:);
                V_used=unique(Obj.(name).T(:,1:3));
                Obj.(name).V=Obj.V(V_used,:);
                Obj.(name).N=Obj.N(Obj.(name).F,:);
                Obj.(name).VN=zeros(size(Obj.(name).V,1),4);
                for j=1:size(Obj.(name).V,1)
                    [r,~]=find(Obj.(name).T(:,1:3)==Obj.(name).V(j,4));
                    N_used=Obj.(name).N(r,1:3);
                    VN_sum=[sum(N_used(:,1)),sum(N_used(:,2)),sum(N_used(:,3))];
                    VN=VN_sum/norm(VN_sum);
                    Obj.(name).VN(j,:)=[VN,Obj.(name).V(j,4)];
                end
                % 'D' is for the deviation of each vertices
                Obj.(name).D=zeros(size(Obj.(name).V,1),1);
            end
            
            Obj.V(:,4)=[];
            Obj.T(:,4)=[];
            Obj.N(:,4)=[];
            
        end
        
        % Combination of deviations and nominal model
        function Comb( Obj, Scale )
            
            % ELM is generated during segmentation
            
            % K is generated, if it is empty
            if isempty(Obj.K)
                E=2.95e11;
                A=0.0001;
                nv=size(Obj.V,1);
                Obj.K=sparse(3*nv,3*nv);
                for n1=1:size(Obj.ELM,1)
                    a=Obj.ELM(n1,1);
                    b=Obj.ELM(n1,2);
                    node1=Obj.V(a,1:3);
                    node2=Obj.V(b,1:3);
                    %--------------------------------------------------------------------------
                    L=norm(node2-node1);
                    cos1=(node2(1)-node1(1))/L;
                    cos2=(node2(2)-node1(2))/L;
                    cos3=(node2(3)-node1(3))/L;
                    T=[cos1,cos2,cos3,0,0,0;0,0,0,cos1,cos2,cos3];
                    kk=E*A/L*(T')*[1,-1;-1,1]*T;
                    %--------------------------------------------------------------------------
                    DOF(1)=3*a-2;
                    DOF(2)=3*a-1;
                    DOF(3)=3*a;
                    DOF(4)=3*b-2;
                    DOF(5)=3*b-1;
                    DOF(6)=3*b;
                    for n2=1:6
                        for n3=1:6
                            Obj.K(DOF(n2),DOF(n3))= Obj.K(DOF(n2),DOF(n3))+kk(n2,n3);
                        end
                    end
                end
            end
            
            % C is generated, if it is empty
            nv=size(Obj.V,1);
            if isempty(Obj.C)
                mark=0;
                for i=1:Obj.N_Surf
                    name=['SF',num2str(i)];
                    Obj.(name).C=sparse(size(Obj.(name).VN,1),3*nv);
                    for j=1:size(Obj.(name).VN,1)
                        Obj.(name).C(j,(3*Obj.(name).VN(j,4)-2):3*Obj.(name).VN(j,4))=Obj.(name).VN(j,1:3);
                    end
                    mark=mark+j;
                end
                
                Obj.C=sparse(mark,3*nv);
                mark1=1;
                for i=1:Obj.N_Surf
                    name=['SF',num2str(i)];
                    mark2=size(Obj.(name).V,1);
                    Obj.C(mark1:(mark1+mark2-1),:)=Obj.(name).C;
                    mark1=mark1+mark2;
                end
            end
            
            % Get and Scale deviation matrix 'D'
            Obj.D=zeros(size(Obj.C,1),1);
            mark1=1;
            for i=1:Obj.N_Surf
                name=['SF',num2str(i)];
                mark2=size(Obj.(name).V,1);
                Obj.D(mark1:(mark1+mark2-1),1)=Obj.(name).D;
                mark1=mark1+mark2;
            end
            Obj.D=Scale*Obj.D;
            
            % FEA, 'SM' is the Skin Model
            Obj.SM.K=Obj.K+Obj.S*(Obj.C')*Obj.C;
            Obj.SM.P=Obj.S*(Obj.C')*Obj.D;
            Obj.SM.U=Obj.SM.K\Obj.SM.P;
            Obj.SM.V=Obj.V;
            for i=1:size(Obj.SM.V,1)
                Obj.SM.V(i,1:3)=Obj.SM.V(i,1:3)+Obj.SM.U((3*i-2):(3*i))';
                Obj.SM.CL(i,1)=dot(Obj.VN(i,1:3),Obj.SM.U((3*i-2):(3*i))');
            end
            
        end
        
        % Translate the feature, 'value' is a row vector
        function TR( Obj, id, value )
            name=['SF',num2str(id)];
            for i=1:size(Obj.(name).VN,1)
                Obj.(name).D(i,1)=dot(Obj.(name).VN(i,1:3),value);
            end
        end
        
        % Rotate the feature, 'value' is a row vector, in degree
        function RO( Obj, id, value )
            value=deg2rad(value);
            name=['SF',num2str(id)];
            ct=mean(Obj.(name).V(:,1:3));
            Rx=[1,0,0;
                0,cos(value(1)),-sin(value(1));
                0,sin(value(1)),cos(value(1))];
            Ry=[cos(value(2)),0,-sin(value(2));
                0,1,0;
                sin(value(2)),0,cos(value(2))];
            Rz=[cos(value(3)),-sin(value(3)),0;
                sin(value(3)),cos(value(3)),0;
                0,0,1;];
            for i=1:size(Obj.(name).V,1)
                d=(Rz*Ry*Rx*(Obj.(name).V(i,1:3)-ct)')'-(Obj.(name).V(i,1:3)-ct);
                Obj.(name).D(i,1)=dot(Obj.(name).VN(i,1:3),d);
            end
        end
        
        % Form error sim, using modes
        function MD(Obj, id_surf, id_mode, scale)
            name=['SF',num2str(id_surf)];
            
            % Calculation of the modes
            EG=zeros(size(Obj.(name).V,1),size(Obj.(name).V,1));
            for i=1:size(Obj.(name).T,1)
                n1=find(Obj.(name).V(:,4)==Obj.(name).T(i,1));
                n2=find(Obj.(name).V(:,4)==Obj.(name).T(i,2));
                n3=find(Obj.(name).V(:,4)==Obj.(name).T(i,3));
                
                if EG(n1,n2)==0
                    EG(n1,n2)=i;
                else
                    EG(n2,n1)=i;
                end
                
                if EG(n2,n3)==0
                    EG(n2,n3)=i;
                else
                    EG(n3,n2)=i;
                end
                
                if EG(n3,n1)==0
                    EG(n3,n1)=i;
                else
                    EG(n1,n3)=i;
                end
            end
            EV=[];
            ET=[];
            for i=1:size(EG,1)-1
                for j=i:size(EG,1)
                    if EG(i,j)~=0
                        EV=[EV;i,j];
                        ET=[ET;EG(i,j),EG(j,i)];
                    end
                end
            end
            
            % Calculation of the modes
            n_e=size(EV,1);
            W=zeros(n_e,1);
            for i=1:n_e
                W(i,1)=norm(Obj.(name).V(EV(i,1),1:3)-Obj.(name).V(EV(i,2),1:3));
            end
            n_v=size(Obj.(name).V,1);
            L=zeros(n_v,n_v);
            L2=zeros(n_v,n_v);
            for i=1:n_e
                L(EV(i,1),EV(i,2))=W(i,1);
            end
            L=L+L';
            for i=1:n_v
                L2(i,i)=sum(L(i,:));
            end
            L=L2-L;
            L=sparse(L);
            [Veig,~]=eigs(L,id_mode,'SM');
            Veig=Veig(:,1);

            % Normalize the mode
            m=max(abs(Veig));
            Veig=Veig/m*0.5;
            Obj.(name).D=zeros(size(Obj.(name).V,1),1);
            Obj.(name).D=Obj.(name).D+Veig*scale;
            
            % Show the mode simulated
            Color=zeros(size(Obj.V,1),1);
            div=zeros(size(Obj.V,1),3);
            for i=1:size(Obj.(name).V,1)
                Color(Obj.(name).V(i,4),1)=Veig(i,1);
                div(Obj.(name).V(i,4),1:3)=Obj.(name).VN(i,1:3)*Veig(i,1)*scale;
            end
            figure
            trisurf(Obj.(name).T(:,1:3),Obj.V(:,1)+div(:,1),Obj.V(:,2)+div(:,2),Obj.V(:,3)+div(:,3),Color);
            colormap jet
            axis equal
            axis off
        end
        
        % Reset the deviation value, to simulate new ones
        function ResetD( Obj )
            for i=1:Obj.N_Surf
                name=['SF',num2str(i)];
                Obj.(name).D=zeros(size(Obj.(name).V,1),1);
            end
        end
        
        % Plot original model
        function ShowORG( Obj )
            figure
            map=trisurf(Obj.T,Obj.V(:,1),Obj.V(:,2),Obj.V(:,3));
            set(map,'FaceColor',[1,1,1]);
            axis equal
            axis off
        end
        
        % Plot segmented model
        function ShowSEG( Obj , id )
            % If want show all features, no input
            % If want to show certain surface, input its id (number)
            if nargin==1
                figure
                for i=1:Obj.N_Surf
                    name=['SF',num2str(i)];
                    map=trisurf(Obj.(name).T(:,1:3),Obj.V(:,1),Obj.V(:,2),Obj.V(:,3));
                    set(map,'FaceColor',rand(1,3));
                    hold on
                end
            elseif nargin==2
                name=['SF',num2str(id)];
                map=trisurf(Obj.(name).T(:,1:3),Obj.V(:,1),Obj.V(:,2),Obj.V(:,3));
                set(map,'FaceColor',rand(1,3));
                hold on
            end
            axis equal
            axis off
        end
        
        % Plot generated Skin Model
        function ShowSM( Obj )
            figure
            trisurf(Obj.T,Obj.SM.V(:,1),Obj.SM.V(:,2),Obj.SM.V(:,3),Obj.SM.CL,'FaceColor','Interp');
            colormap jet
            axis equal
            axis off
        end
        
    end
    
end

