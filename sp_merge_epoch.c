#include "mex.h"
/*This function merges detected spikes together when the distance between them 
 * than a specified minimal distance
 * epin : input index (epoch) where spikes are present 
 * mindist : minimum distance between two spikes
 * epout : output index (epoch) where spikes are merged together
 */
void mexFunction( int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[] )
{
    //epoch in, epoch out, temp epoch, previous epoch, mindist
    double *epin,*epout,*eptmp,prevep,mindist;        
    size_t i,m,n,sz,lg=0;    
    if (nrhs!=2) return;
    m=mxGetM(prhs[0]);
    n=mxGetN(prhs[0]);    
    if (m!=1 && n!=1) return;
    epin=mxGetPr(prhs[0]);
    sz=m*n;
    mindist=mxGetScalar(prhs[1]);    
    eptmp=mxMalloc(sizeof(double)*sz);           
    prevep=-mindist-1;
    
    for (i=0;i<sz;i++)
    {
        if (epin[i]-prevep>mindist) 
        {
            eptmp[lg++]=epin[i];
            prevep=epin[i];
        }
    }    
    
    if (m>n)
        plhs[0]=mxCreateDoubleMatrix(lg,1,mxREAL);    
    else
        plhs[0]=mxCreateDoubleMatrix(1,lg,mxREAL);    
    epout=mxGetPr(plhs[0]);
    
    for (i=0;i<lg;i++) epout[i]=eptmp[i];
        
    mxFree(eptmp);
    return;
}