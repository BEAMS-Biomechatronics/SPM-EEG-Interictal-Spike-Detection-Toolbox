#include "mex.h"
/*This function adjust the position of a spike by finding the minimal value 
 * of the signal just after the approximative position
 * posin : input position
 * sigin : signal in
 * maxdist : maximal distance to search in front of the current position
 * posout : output adjusted position
 */
#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))
#define MAX(X, Y) (((X) > (Y)) ? (X) : (Y))
#define ABS(x) ((x)<0 ? (-x) : (x))

void mexFunction( int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[] )
{    
    double *posin,*sigin,*posout;
    size_t i,j,m,n,sz,lgsig,ind,indmax,lgmax,lgmin,maxdist,ms,ns;    
    if (nrhs!=3 || nlhs!=1) return;    
    m=mxGetM(prhs[0]);
    n=mxGetN(prhs[0]);    
    if (m!=1 && n!=1) return; //one dimension size should be one !
    sz=m*n;
    posin=mxGetPr(prhs[0]);
    sigin=mxGetPr(prhs[1]);
    ms=mxGetM(prhs[1]);
    ns=mxGetN(prhs[1]);
    lgsig=ms*ns;
    if (ms!=1 && ns!=1) return; //one dimension size should be one !
    maxdist=(size_t)mxGetScalar(prhs[2]); 
    if (m>n)
        plhs[0]=mxCreateDoubleMatrix(sz,1,mxREAL);    
    else
        plhs[0]=mxCreateDoubleMatrix(1,sz,mxREAL);       
    posout=mxGetPr(plhs[0]);
    for (i=0;i<sz;i++) {
        indmax=ind=(size_t)posin[i]-1; //current position of maximum is the same (index C=index matlab-1)
        lgmax=MIN(lgsig,indmax+maxdist);
        lgmin=MAX(0,indmax-maxdist);        
        for (j=lgmin;j<lgmax;j++)
            if ((sigin[j])>(sigin[indmax])) indmax=j;
        posout[i]=(double)indmax+1;
    }    
    return;
}
