#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int count cl, i;

int main(){
        Seed s = makeSeed(myProcessor);
        for(i=0; i<100000/P;i++){
        x= random(s);
        y= random(s);
        if(x*x+y*y < 1.0){
                count++;
        }
        send(0,1,4,&count);
        if(myProcessorNum()==0){
                globalCount = 0.0;
                for(i=0; i<maxProcessors(); i++){
                        recv(i,1,4,c);
                        globalCount += c;
                }
                printf("pi=%f\n",4*globalCount/100000)
        }
        return 0;
}
