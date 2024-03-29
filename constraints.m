function [FI,FI_q,FI_t] = constraints(q,elements,connections,guidings,t)
FI=[];
FI_q=zeros(0,height(q));
FI_t=zeros(2*(width(connections.pin)+width(connections.slider)),1);
Omega = [0,-1;1,0];
eps = 1e-6;
for connection = connections.pin
    i=connection.connection(1);
    j=connection.connection(2);
    Sa = elements(i).vertices(:,connection.vertices(1));
    Sb = elements(j).vertices(:,connection.vertices(2));
    i=3*(i-1)-2;
    j=3*(j-1)-2;
    temp = zeros(2,height(q));
    if i <= 0
        r_j = q([j,j+1]);
        fi_j = q(j+2);
        R_j = Rot(fi_j);
        FI = [FI;Sa-(r_j+R_j*Sb)];
        temp([1,2],j:j+2) = [-eye(2),-Omega*R_j*Sb];
    elseif j <= 0
        r_i = q([i,i+1]);
        fi_i = q(i+2);
        R_i = Rot(fi_i);
        FI = [FI;r_i+R_i*Sa-Sb];
        temp([1,2],i:i+2) = [eye(2),Omega*R_i*Sa];
    else
        r_i = q([i,i+1]);
        r_j = q([j,j+1]);
        fi_i = q(i+2);
        fi_j = q(j+2);
        R_i = Rot(fi_i);
        R_j = Rot(fi_j);
        FI = [FI;r_i+R_i*Sa-(r_j+R_j*Sb)];
        temp([1,2],i:i+2) = [eye(2),Omega*R_i*Sa];
        temp([1,2],j:j+2) = [-eye(2),-Omega*R_j*Sb];
    end
    FI_q([end+1,end+2],:) = temp;
end
for connection = connections.slider
    i=connection.connection(1);
    j=connection.connection(2);
    Sa = elements(i).vertices(:,connection.vertices(1));
    Sb = elements(j).vertices(:,connection.vertices(2));
    i=3*(i-1)-2;
    j=3*(j-1)-2;
    temp = zeros(2,height(q));
    if i <= 0
        r_j = q([j,j+1]);
        fi_j = q(j+2);
        R_j = Rot(fi_j);
        v = connection.v;
        fi_0 = connection.fi0;
        FI = [FI;(R_j*v)'*(r_j-Sa)+v'*Sb];
        FI = [FI;wrapToPi(-fi_j-fi_0)];
        temp(1,j:j+2) = [(R_j*v)',(Omega*R_j*v)'*(r_j-Sa)];
        temp(2,j+2) = -1;
    elseif j <= 0
        r_i = q([i,i+1]);
        fi_i = q(i+2);
        R_i = Rot(fi_i);
        v = connection.v;
        fi_0 = connection.fi0;
        FI = [FI;(v)'*(-r_i-R_i*Sa)+v'*Sb];
        FI = [FI; wrapToPi(fi_i-fi_0)];
        temp(1,i:i+2) = [-v',-v'*Omega*R_i*Sa];
        temp(2,i+2) = 1;
    else
        r_i = q([i,i+1]);
        r_j = q([j,j+1]);
        fi_i = q(i+2);
        fi_j = q(j+2);
        R_i = Rot(fi_i);
        R_j = Rot(fi_j);
        v = connection.v;
        fi_0 = connection.fi0;
        FI = [FI;(R_j*v)'*(r_j-r_i-R_i*Sa)+v'*Sb];
        FI = [FI; wrapToPi(fi_i-fi_j-fi_0)];
        temp(1,i:i+2) = [-(R_j*v)',-(R_j*v)'*Omega*R_i*Sa];
        temp(1,j:j+2) = [(R_j*v)',(Omega*R_j*v)'*(r_j-r_i-R_i*Sa)];
        temp(2,i+2) = 1;
        temp(2,j+2) = -1;
    end
    FI_q([end+1,end+2],:) = temp;
end
if height(FI_q) == width(FI_q)
    warning('Zadane więzy kinematyczne odbierają wszystkie swobody ruchu');
elseif height(FI_q) >= width(FI_q)
    throw(MException('MyComponent:tooManyConstraints','Zadane więzy kinematyczne przesztywniają układ -> rozwiązanie dla ciał sztywnych niemożliwe'))
end
for guiding = guidings
    wC = guiding.whichConnection;
    formula = guiding.formula;
    temp = zeros(1,height(q));
    if wC <= width(connections.pin)
        connection = connections.pin(wC);
        i = connection.connection(1); 
        j = connection.connection(2);
        i=3*(i-1)-2;
        j=3*(j-1)-2;
        if i <= 0
            fi_j = q(j+2);
            FI(end+1) = wrapToPi(-fi_j-formula(t));
            temp(j+2) = -1;
        elseif j <= 0
            fi_i = q(i+2);
            FI(end+1) = wrapToPi(fi_i-formula(t));
            temp(i+2) = 1;
        else
            fi_i = q(i+2);
            fi_j = q(j+2);
            FI(end+1) = wrapToPi(fi_i-fi_j-formula(t));
            temp(i+2) = 1;
            temp(j+2) = -1;
        end
    else
        wC = wC-width(connections.pin);
        connection = connections.slider(wC);
        i = connection.connection(1); 
        j = connection.connection(2);
        Sa = elements(i).vertices(:,connection.vertices(1));
        Sb = elements(j).vertices(:,connection.vertices(2));
        i=3*(i-1)-2;
        j=3*(j-1)-2;
        if i<=0
        r_j = q([j,j+1]);
        fi_j = q(j+2);
        R_j = Rot(fi_j);
        v = connection.v;
        v = v/norm(v);
        FI = [FI;(R_j*Omega*v)'*(r_j-Sa)+(Omega*v)'*Sb-formula(t)];
        temp(j:j+2) = [(R_j*Omega*v)',-(R_j*v)'*(r_j-Sa)];
        elseif j<=0
        r_i = q([i,i+1]);
        fi_i = q(i+2);
        R_i = Rot(fi_i);
        v = connection.v;
        v = v/norm(v);
        FI = [FI;(Omega*v)'*(-r_i-R_i*Sa)+(Omega*v)'*Sb-formula(t)];
        temp(i:i+2) = [-(Omega*v)',-(Omega*v)'*Omega*R_i*Sa];
        else
        r_i = q([i,i+1]);
        r_j = q([j,j+1]);
        fi_i = q(i+2);
        fi_j = q(j+2);
        R_i = Rot(fi_i);
        R_j = Rot(fi_j);
        v = connection.v;
        v = v/norm(v);
        FI = [FI;(R_j*Omega*v)'*(r_j-r_i-R_i*Sa)+(Omega*v)'*Sb-formula(t)];
        temp(i:i+2) = [-(R_j*Omega*v)',-(R_j*Omega*v)'*Omega*R_i*Sa];
        temp(j:j+2) = [(R_j*Omega*v)',-(R_j*v)'*(r_j-r_i-R_i*Sa)];
        end
    end
    FI_q(end+1,:) = temp(:);
    formulaDiff = matlabFunction(diff(sym(formula)));
    FI_t(end+1) = -formulaDiff(t);
end
if height(FI_q) == width(FI_q)
    if abs(det(FI_q)) <= eps
        throw(MException('MyComponent:singularity','Wyznacznik macierzy Jacobiego zeruje się -> układ znalazł się w położeniu osobliwym')) 
    end
elseif height(FI_q) < width(FI_q)
    throw(MException('MyComponent:notEnoughConstraints','Zadane więzy (kinematyczne i kierujące) nie odbierają wszystkich stopni swobody'))
else
    throw(MException('MyComponent:tooManyConstraints','Zadane więzy (kinematyczne i kierujące) przesztywniają układ -> rozwiązanie dla ciał sztywnych niemożliwe'))
end
end  